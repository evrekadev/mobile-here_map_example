import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:here_maps_example/helpers/evreka_here_location_provider.dart';
import 'package:here_maps_example/helpers/evreka_here_route_calculator.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/location.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/routing.dart' as here;
import 'package:screenshot/screenshot.dart';

class EvrekaHereMapController {
  final HereMapController hereMapController;
  final routeCalculator = EvrekaHereRouteCalculator();
  final locationProvider = EvrekaHereLocationProvider();
  final _screenshotController = ScreenshotController();

  late final VisualNavigator _visualNavigator;

  late final LocationIndicator _locationIndicator;

  final List<MapMarker> _mapMarkers = [];

  ValueNotifier<bool> isTrackingNotifier = ValueNotifier(true);

  set isTracking(bool value) {
    if (value == isTrackingNotifier.value) return;
    isTrackingNotifier.value = value;
    if (value) {
      _visualNavigator.cameraBehavior = DynamicCameraBehavior();
      return;
    }
    _visualNavigator.cameraBehavior = null;
  }

  bool get isTracking => isTrackingNotifier.value;

  bool get routeStarted => _visualNavigator.route != null;

  EvrekaHereMapController(this.hereMapController) {
    try {
      _visualNavigator = VisualNavigator();
    } on InstantiationException {
      throw Exception("Initialization of VisualNavigator failed.");
    }

    // Enable auto-zoom during guidance.
    _visualNavigator.cameraBehavior = DynamicCameraBehavior();

    // This enables a navigation view including a rendered navigation arrow.
    _visualNavigator.startRendering(hereMapController);

    locationProvider.startLocating(_visualNavigator, LocationAccuracy.navigation);

    _locationIndicator = LocationIndicator();

    _locationIndicator.enable(hereMapController);
    _locationIndicator.locationIndicatorStyle = LocationIndicatorIndicatorStyle.navigation;
  }

  Future<void> moveToCurrentPosition() async {
    var currentCoordinates = locationProvider.getLastKnownLocation()?.coordinates;
    currentCoordinates ??= await getGeoLocatorCurrentPosition();
    moveToCoordinates(currentCoordinates);
  }

  void moveToCoordinates(GeoCoordinates geoCoordinates) {
    final geoCoordinatesUpdate = GeoCoordinatesUpdate.fromGeoCoordinates(geoCoordinates);
    double bowFactor = 1;
    MapCameraAnimation animation = MapCameraAnimationFactory.flyTo(
      geoCoordinatesUpdate,
      bowFactor,
      const Duration(seconds: 3),
    );
    hereMapController.camera.startAnimation(animation);
  }

  Future<here.Route?> calculateTruckRoute(List<GeoCoordinates> destinations) async {
    final List<here.Waypoint> waypoints = [];

    final startCoordinates = await getGeoLocatorCurrentPosition();

    waypoints.add(here.Waypoint.withDefaults(startCoordinates));

    for (var destination in destinations) {
      waypoints.add(here.Waypoint.withDefaults(destination));
    }

    Completer<here.Route?> completer = Completer<here.Route?>();

    routeCalculator.calculateTruckRoute(waypoints, (routingError, routes) {
      if (routingError != null) {
        debugPrint('Error while calculating a route: $routingError');
        completer.complete(null);
        return;
      }
      completer.complete(routes!.first);
    });

    return await completer.future;
  }

  void startNavigation(here.Route route) {
    _visualNavigator.route = route;
  }

  void stopNavigation() {
    _visualNavigator.route = null;
  }

  Future<Uint8List> _loadFileAsUint8List(String assetPathToFile) async {
    // The path refers to the assets directory as specified in pubspec.yaml.
    ByteData fileData = await rootBundle.load(assetPathToFile);
    return Uint8List.view(fileData.buffer);
  }

  Future<void> createAndAddMapMarkerAtGeoCoordinates(GeoCoordinates geoCoordinates, {String? label}) async {
//    Uint8List uint8list = await _loadFileAsUint8List('assets/map-marker.png');

    Uint8List uint8list = await _screenshotController.captureFromWidget(
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            width: 342,
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Center(
              child: Text(
                label ?? "",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Image.asset(
            'assets/map-marker.png',
            width: 342,
            height: 512,
          ),
        ],
      ),
    );

    final MapImage mapImage = MapImage.withImageDataImageFormatWidthAndHeight(
      uint8list,
      ImageFormat.png,
      171,
      300,
    );

    // By default, the anchor point is set to 0.5, 0.5 (= centered).
    // Here the bottom, middle position should point to the location.
    Anchor2D anchor2D = Anchor2D.withHorizontalAndVertical(0.5, 1);

    final mapMarker = MapMarker.withAnchor(
      geoCoordinates,
      mapImage,
      anchor2D,
    );

    Metadata metadata = Metadata();
    metadata.setString("label", label ?? "");
    mapMarker.metadata = metadata;

    addMapMarker(mapMarker);
  }

  void addMapMarker(MapMarker mapMarker) {
    _mapMarkers.add(mapMarker);
    hereMapController.mapScene.addMapMarker(mapMarker);
  }

  void clearMapMarkers() {
    for (var mapMarker in _mapMarkers) {
      hereMapController.mapScene.removeMapMarker(mapMarker);
    }
    _mapMarkers.clear();
  }

  void clearMap() {
    clearMapMarkers();
  }

  void detach() {
    _visualNavigator.stopRendering();
  }

  Future<GeoCoordinates> getGeoLocatorCurrentPosition() async {
    final geolocator.Position position = await geolocator.Geolocator.getCurrentPosition();

    return GeoCoordinates(position.latitude, position.longitude);
  }
}
