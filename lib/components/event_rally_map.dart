import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:squadquest/logger.dart';
import 'package:squadquest/controllers/auth.dart';
import 'package:squadquest/models/instance.dart';

class EventRallyMap extends ConsumerStatefulWidget {
  final String title;
  final InstanceID eventId;
  final LatLng mapCenter;
  final LatLng? initialRallyPoint;

  const EventRallyMap(
      {super.key,
      this.title = 'Set rally point',
      required this.eventId,
      this.mapCenter = const LatLng(39.9550, -75.1605),
      this.initialRallyPoint});

  @override
  ConsumerState<EventRallyMap> createState() => _EventRallyMapState();
}

class _EventRallyMapState extends ConsumerState<EventRallyMap> {
  MapLibreMapController? controller;
  late LatLng rallyPoint;
  Symbol? dragSymbol;

  @override
  void initState() {
    super.initState();
    rallyPoint = widget.initialRallyPoint ?? widget.mapCenter;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider);

    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
        height: MediaQuery.of(context).size.height * .75,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(alignment: Alignment.center, children: [
            Positioned(
                right: 12,
                child: IconButton(
                    icon: const Icon(Icons.check), // Your desired icon
                    onPressed: () {
                      Navigator.of(context).pop(rallyPoint);
                    })),
            Positioned(
                left: 12,
                child: IconButton(
                    icon: const Icon(Icons.close), // Your desired icon
                    onPressed: () {
                      Navigator.of(context).pop();
                    })),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ]),
          Expanded(
              child: MapLibreMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoadedCallback,
            styleString:
                'https://api.maptiler.com/maps/08847b31-fc27-462a-b87e-2e8d8a700529/style.json?key=XYHvSt2RxwZPOxjSj98n',
            myLocationEnabled: true,
            myLocationRenderMode: MyLocationRenderMode.compass,
            myLocationTrackingMode: MyLocationTrackingMode.tracking,
            initialCameraPosition: const CameraPosition(
              target: LatLng(39.9550, -75.1605),
              zoom: 11.75,
            ),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ))
        ]));
  }

  void _onMapCreated(MapLibreMapController controller) {
    logger.d('EventRallyMap._onMapCreated');
    this.controller = controller;
  }

  void _onStyleLoadedCallback() async {
    logger.d('EventRallyMap._onStyleLoadedCallback');

    // configure symbols
    await controller!.setSymbolIconAllowOverlap(true);
    await controller!.setSymbolTextAllowOverlap(true);
    await controller!.addImage(
        'drag-marker',
        (await rootBundle.load('assets/symbols/drag-marker.png'))
            .buffer
            .asUint8List());

    dragSymbol = await controller!.addSymbol(SymbolOptions(
        geometry: rallyPoint,
        iconImage: 'drag-marker',
        iconSize: kIsWeb ? 0.25 : 0.5, // TODO: test web scale
        iconAnchor: 'top',
        draggable: true));

    controller!.onFeatureDrag.add(_onDrag);
  }

  _onDrag(dynamic id,
      {required Point<double> point,
      required LatLng origin,
      required LatLng current,
      required LatLng delta,
      required DragEventType eventType}) {
    if (eventType != DragEventType.end) {
      return;
    }

    rallyPoint = dragSymbol!.options.geometry!;
  }
}