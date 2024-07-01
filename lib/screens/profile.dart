import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:squadquest/models/topic_member.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:squadquest/logger.dart';
import 'package:squadquest/app_scaffold.dart';
import 'package:squadquest/services/supabase.dart';
import 'package:squadquest/services/profiles_cache.dart';
import 'package:squadquest/models/user.dart';
import 'package:squadquest/models/instance.dart';
import 'package:squadquest/components/tiles/instance.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final UserID userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  AsyncValue<UserProfile> profileAsync = const AsyncValue.loading();
  AsyncValue<List<InstanceMember>> rsvpsAsync = const AsyncValue.loading();
  AsyncValue<List<TopicMember>> topicMembershipsAsync =
      const AsyncValue.loading();

  @override
  void initState() {
    super.initState();

    final supabase = ref.read(supabaseClientProvider);
    final profilesCache = ref.read(profilesCacheProvider.notifier);

    // load profile
    profilesCache.getById(widget.userId).then((profile) {
      setState(() {
        profileAsync = AsyncValue.data(profile);
      });
    });

    // load RSVPs
    supabase
        .from('instance_members')
        .select('*, instance!inner(*)')
        .eq('member', widget.userId)
        .inFilter('status', ['maybe', 'yes', 'omw'])
        .gt('instance.start_time_max', DateTime.now())
        .order('start_time_max', referencedTable: 'instance', ascending: false)
        .withConverter((data) => data.map(InstanceMember.fromMap).toList())
        .then((rsvps) async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            rsvpsAsync = AsyncValue.data(rsvps);
          });
        });

    // load topics
    supabase
        .from('topic_members')
        .select('*, topic(*)')
        .eq('member', widget.userId)
        // .order('name', referencedTable: 'topic', ascending: true) // why this no work? sorting locally below
        .withConverter((data) => data.map(TopicMember.fromMap).toList())
        .then((topicMemberships) async {
      await Future.delayed(const Duration(seconds: 1));
      topicMemberships.sort((a, b) => a.topic!.name.compareTo(b.topic!.name));
      setState(() {
        topicMembershipsAsync = AsyncValue.data(topicMemberships);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showDrawer: !context.canPop(),
      title: profileAsync.when(
        data: (UserProfile profile) => profile.fullName,
        loading: () => '',
        error: (_, __) => 'Error loading profile',
      ),
      bodyPadding: const EdgeInsets.all(16),
      body: profileAsync.when(
          error: (error, __) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
          data: (UserProfile profile) => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Expanded(
                            flex: 2,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                      text: TextSpan(children: [
                                    const TextSpan(text: 'Phone: '),
                                    TextSpan(
                                      text: profile.phoneFormatted,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap =
                                            () => launchUrl(profile.phoneUri!),
                                    )
                                  ])),
                                ])),
                        // if (event.rallyPoint != null)
                        const Expanded(
                            flex: 1,
                            child: AspectRatio(
                                aspectRatio: 1,
                                child: ColoredBox(color: Colors.blue)))
                      ])),
                  SliverPersistentHeader(
                    delegate: _SectionHeaderDelegate('I\'m going to'),
                    pinned: true,
                  ),
                  rsvpsAsync.when(
                      loading: () => const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator())),
                      error: (error, _) =>
                          SliverToBoxAdapter(child: Text(error.toString())),
                      data: (rsvps) => SliverList.list(
                            children: rsvps
                                .map((rsvp) => InstanceTile(
                                    instance: rsvp.instance!,
                                    rsvp: rsvp,
                                    onTap: () {
                                      context.pushNamed('event-details',
                                          pathParameters: {
                                            'id': rsvp.instance!.id!,
                                          });
                                    }))
                                .toList(),
                          )),
                  SliverPersistentHeader(
                    delegate: _SectionHeaderDelegate('Subscribed topics'),
                    pinned: true,
                  ),
                  topicMembershipsAsync.when(
                      loading: () => const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator())),
                      error: (error, _) =>
                          SliverToBoxAdapter(child: Text(error.toString())),
                      data: (topicMemberships) => SliverList.list(
                            children: topicMemberships
                                .map((topicMembership) => ListTile(
                                    title: Text(topicMembership.topic!.name)))
                                .toList(),
                          )),
                ],
              )),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double height = 50;

  _SectionHeaderDelegate(this.title);

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    return Container(
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18),
          )),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
