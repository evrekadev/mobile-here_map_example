import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:here_maps_example/helpers/evreka_here_map_controller.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/consent.dart';
import 'package:here_sdk/routing.dart' as here;
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  EvrekaHereMapController? _evrekaHereMapController;
  ConsentEngine? _consentEngine;

  final GeoCoordinates _marker1Coordinates = GeoCoordinates(39.761234, 36.987950);
  final GeoCoordinates _marker2Coordinates = GeoCoordinates(39.762050, 36.984216);
  final GeoCoordinates _marker3Coordinates = GeoCoordinates(39.759378, 36.987006);
  final GeoCoordinates _marker4Coordinates = GeoCoordinates(39.763683, 36.986973);
  final GeoCoordinates _marker5Coordinates = GeoCoordinates(39.763081, 36.988443);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Free HERE SDK resources before the application shuts down.
    SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _evrekaHereMapController?.detach();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        floatingActionButton: _evrekaHereMapController?.isTrackingNotifier == null
            ? null
            : ValueListenableBuilder(
                valueListenable: _evrekaHereMapController!.isTrackingNotifier,
                builder: (context, isTracking, _) {
                  return isTracking
                      ? const SizedBox()
                      : FloatingActionButton(
                          onPressed: () {
                            _evrekaHereMapController?.moveToCurrentPosition();
                            _evrekaHereMapController?.isTracking = true;
                          },
                          child: const Icon(Icons.my_location),
                        );
                }),
        body: SafeArea(
          child: Stack(
            children: [
              HereMap(
                onMapCreated: _onMapCreated,
              ),
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {
                  _evrekaHereMapController?.isTracking = false;
                },
              ),
              if (_evrekaHereMapController != null)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _button(
                              "Add markers",
                              () async {
                                await createAndAddMarkers();
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            _button(
                              "Clear markers",
                              () async {
                                _evrekaHereMapController?.clearMapMarkers();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _evrekaHereMapController!.routeStarted
                                ? _button(
                                    "Stop route",
                                    () {
                                      _evrekaHereMapController?.stopNavigation();
                                      setState(() {});
                                    },
                                  )
                                : _button(
                                    "Start route",
                                    () async {
                                      final here.Route? route = await _evrekaHereMapController?.calculateTruckRoute([
                                        _marker1Coordinates,
                                        _marker2Coordinates,
                                        _marker3Coordinates,
                                        _marker4Coordinates,
                                        _marker5Coordinates,
                                      ]);
                                      if (route == null) {
                                        await _showToast("Failed to calculate a route.");
                                        return;
                                      }
                                      _evrekaHereMapController?.startNavigation(route);
                                      setState(() {});
                                    },
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback callback) {
    return ElevatedButton(
      onPressed: callback,
      child: Text(text),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    try {
      _consentEngine = ConsentEngine();
    } on InstantiationException {
      throw ("Initialization of ConsentEngine failed.");
    }
    hereMapController.mapScene.loadSceneForMapScheme(
      MapScheme.normalDay,
      (MapError? error) async {
        if (error != null) {
          return;
        }

        // 2. Once permissions are granted, we request the user's consent decision which is required for HERE Positioning.
        if (_consentEngine?.userConsentState == ConsentUserReply.notHandled) {
          await _requestConsent();
        }

        if (!await _requestPermissions()) {
          await _showToast("Cannot start app: Location service and permissions are needed for this app.");
          // Let the user set the permissions from the system settings as fallback.
          openAppSettings();
          SystemNavigator.pop();
          return;
        }

        _evrekaHereMapController = EvrekaHereMapController(hereMapController);

        _evrekaHereMapController?.moveToCurrentPosition();

        final here.Route? route = await _evrekaHereMapController?.calculateTruckRoute([
          _marker1Coordinates,
          _marker2Coordinates,
          _marker3Coordinates,
          _marker4Coordinates,
          _marker5Coordinates,
        ]);

        if (route == null) {
          await _showToast("Failed to calculate a route.");
          return;
        }

        _evrekaHereMapController?.startNavigation(route);
        setState(() {});
      },
    );
  }

  Future<void> createAndAddMarkers() async {
    if (_evrekaHereMapController == null) return;

    await _evrekaHereMapController!.createAndAddMapMarkerAtGeoCoordinates(_marker1Coordinates, label: "1");
    await _evrekaHereMapController!.createAndAddMapMarkerAtGeoCoordinates(_marker2Coordinates, label: "2");
    await _evrekaHereMapController!.createAndAddMapMarkerAtGeoCoordinates(_marker3Coordinates, label: "3");
    await _evrekaHereMapController!.createAndAddMapMarkerAtGeoCoordinates(_marker4Coordinates, label: "4");
    await _evrekaHereMapController!.createAndAddMapMarkerAtGeoCoordinates(_marker5Coordinates, label: "5");
  }

  Future<void> _requestConsent() async {
    if (!Platform.isIOS) {
      // This shows a localized widget that asks the user if data can be collected or not.
      await _consentEngine?.requestUserConsent(context);
    }
  }

  Future<void> _showToast(String message) async {
    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<bool> _requestPermissions() async {
    if (!await Permission.location.serviceStatus.isEnabled) {
      return false;
    }

    if (!await Permission.location.request().isGranted) {
      return false;
    }

    if (Platform.isAndroid) {
      // This permission is optionally needed on Android devices >= Q to improve the positioning signal.
      Permission.activityRecognition.request();
    }

    // All required permissions granted.
    return true;
  }
}
