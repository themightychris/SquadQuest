import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grouped_list/grouped_list.dart';

import 'package:squad_quest/common.dart';
import 'package:squad_quest/drawer.dart';
import 'package:squad_quest/controllers/auth.dart';
import 'package:squad_quest/controllers/friends.dart';
import 'package:squad_quest/models/user.dart';
import 'package:squad_quest/models/friend.dart';

final _statusGroupOrder = {
  FriendStatus.requested: 0,
  FriendStatus.accepted: 1,
  FriendStatus.declined: 2,
};

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  static final _requestDateFormat = DateFormat('MMM d, h:mm a');

  UserProfile _getFriendProfile(String myUserId, Friend friend) {
    if (friend.requesterId == myUserId) {
      return friend.requestee!;
    }

    return friend.requester!;
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = ref.watch(userProvider)!.id;
    final friendsList = ref.watch(friendsProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buddy List'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final String? phone = await _showAddFriendDialog();

            if (phone == null) {
              // dialog cancelled
              return;
            }

            try {
              await ref.read(friendsProvider.notifier).sendFriendRequest(phone);
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to send friend request:\n\n$error'),
              ));
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Friend request sent!'),
            ));
          },
          child: const Icon(Icons.person_add),
        ),
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: () async {
            return ref.read(friendsProvider.notifier).refresh();
          },
          child: friendsList.when(
              data: (friends) {
                return GroupedListView(
                  elements: friends,
                  useStickyGroupSeparators: true,
                  // floatingHeader: true,
                  stickyHeaderBackgroundColor:
                      Theme.of(context).scaffoldBackgroundColor,
                  groupBy: (Friend friend) => friend.status,
                  groupComparator: (group1, group2) {
                    return _statusGroupOrder[group1]!
                        .compareTo(_statusGroupOrder[group2]!);
                  },
                  groupSeparatorBuilder: (FriendStatus group) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        switch (group) {
                          FriendStatus.requested => 'Request pending',
                          FriendStatus.accepted => 'My Buddies',
                          FriendStatus.declined => 'Declined',
                        },
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      )),
                  itemBuilder: (context, friend) {
                    final friendProfile = _getFriendProfile(myUserId, friend);
                    return ListTile(
                        leading: friendStatusIcons[friend.status],
                        title: Text(
                            '${friendProfile.firstName} ${friendProfile.lastName}'),
                        subtitle: switch (friend.status) {
                          FriendStatus.requested => switch (
                                friend.requester!.id == myUserId) {
                              true => Text(
                                  'Request sent ${_requestDateFormat.format(friend.createdAt!)}'),
                              false => Text(
                                  'Request received ${_requestDateFormat.format(friend.createdAt!)}'),
                            },
                          FriendStatus.accepted => null,
                          FriendStatus.declined =>
                            const Text('Request declined'),
                        });
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error'))),
        ),
      ),
    );
  }

  Future<dynamic> _showAddFriendDialog() async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          final theme = Theme.of(context);
          final formKey = GlobalKey<FormState>();
          final phoneController = TextEditingController();

          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Send friend request',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      autofocus: true,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone),
                        labelText: 'Enter your friend\'s phone number',
                      ),
                      inputFormatters: [phoneInputFilter],
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            normalizePhone(value).length != 11) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                      controller: phoneController,
                      onFieldSubmitted: (_) {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        Navigator.of(context)
                            .pop(normalizePhone(phoneController.text));
                      },
                    ),
                    const SizedBox(height: 32),
                    OverflowBar(
                        alignment: MainAxisAlignment.end,
                        spacing: 16,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              Navigator.of(context)
                                  .pop(normalizePhone(phoneController.text));
                            },
                            child: const Text('Send'),
                          ),
                        ]),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
