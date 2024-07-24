import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/location.dart';

class EvrekaHereLocationProvider implements LocationStatusListener {
  late LocationEngine _locationEngine;
  late LocationListener updateListener;

  EvrekaHereLocationProvider() {
    try {
      _locationEngine = LocationEngine();
    } on InstantiationException {
      throw ("Initialization of LocationEngine failed.");
    }
  }

  Location? getLastKnownLocation() {
    return _locationEngine.lastKnownLocation;
  }

  void startLocating(LocationListener updateListener, LocationAccuracy accuracy) {
    if (_locationEngine.isStarted) {
      return;
    }

    this.updateListener = updateListener;

    _locationEngine.addLocationListener(updateListener);
    _locationEngine.addLocationStatusListener(this);

    _locationEngine.startWithLocationAccuracy(accuracy);
  }

  void stop() {
    if (!_locationEngine.isStarted) {
      return;
    }

    _locationEngine.removeLocationStatusListener(this);
    _locationEngine.removeLocationListener(updateListener);
    _locationEngine.stop();
  }

  @override
  void onStatusChanged(LocationEngineStatus locationEngineStatus) {
    debugPrint("Location engine status: $locationEngineStatus");
  }

  @override
  onFeaturesNotAvailable(List<LocationFeature> features) {
    for (var feature in features) {
      debugPrint("Feature not available: $feature");
    }
  }
}