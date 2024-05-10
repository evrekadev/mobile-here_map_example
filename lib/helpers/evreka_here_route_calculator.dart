import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/routing.dart' as HERE;
import 'package:here_sdk/routing.dart';

class EvrekaHereRouteCalculator {
  late final HERE.RoutingEngine _routingEngine;

  EvrekaHereRouteCalculator() {
    try {
      _routingEngine = HERE.RoutingEngine();
    } on InstantiationException {
      throw Exception('Initialization of RoutingEngine failed.');
    }
  }

  void calculateCarRoute(
      List<Waypoint> waypoints, CalculateRouteCallback calculateRouteCallback) {
    // A route handle is required for the DynamicRoutingEngine to get updates on traffic-optimized routes.
    var routingOptions = HERE.CarOptions();
    routingOptions.routeOptions.enableRouteHandle = true;
    routingOptions.routeOptions.optimizeWaypointsOrder = true;

    _routingEngine.calculateCarRoute(
        waypoints, routingOptions, calculateRouteCallback);
  }

  void calculateTruckRoute(
      List<Waypoint> waypoints, CalculateRouteCallback calculateRouteCallback) {
    // A route handle is required for the DynamicRoutingEngine to get updates on traffic-optimized routes.
    var routingOptions = HERE.TruckOptions();
    routingOptions.routeOptions.enableRouteHandle = true;
    routingOptions.routeOptions.optimizeWaypointsOrder = true;
    _routingEngine.calculateTruckRoute(
        waypoints, routingOptions, calculateRouteCallback);
  }

  void calculatePedestrianRoute(
      List<Waypoint> waypoints, CalculateRouteCallback calculateRouteCallback) {
    // A route handle is required for the DynamicRoutingEngine to get updates on traffic-optimized routes.
    var routingOptions = HERE.PedestrianOptions();
    routingOptions.routeOptions.enableRouteHandle = true;
    routingOptions.routeOptions.optimizeWaypointsOrder = true;

    _routingEngine.calculatePedestrianRoute(
        waypoints, routingOptions, calculateRouteCallback);
  }

  void calculateBusRoute(
      List<Waypoint> waypoints, CalculateRouteCallback calculateRouteCallback) {
    // A route handle is required for the DynamicRoutingEngine to get updates on traffic-optimized routes.
    var routingOptions = HERE.BusOptions();
    routingOptions.routeOptions.enableRouteHandle = true;
    routingOptions.routeOptions.optimizeWaypointsOrder = true;

    _routingEngine.calculateBusRoute(
        waypoints, routingOptions, calculateRouteCallback);
  }

  void calculateBicycleRoute(
      List<Waypoint> waypoints, CalculateRouteCallback calculateRouteCallback) {
    // A route handle is required for the DynamicRoutingEngine to get updates on traffic-optimized routes.
    var routingOptions = HERE.BicycleOptions();
    routingOptions.routeOptions.enableRouteHandle = true;
    routingOptions.routeOptions.optimizeWaypointsOrder = true;

    _routingEngine.calculateBicycleRoute(
        waypoints, routingOptions, calculateRouteCallback);
  }

  void calculateScooterRoute(
      List<Waypoint> waypoints, CalculateRouteCallback calculateRouteCallback) {
    // A route handle is required for the DynamicRoutingEngine to get updates on traffic-optimized routes.
    var routingOptions = HERE.ScooterOptions();
    routingOptions.routeOptions.enableRouteHandle = true;
    routingOptions.routeOptions.optimizeWaypointsOrder = true;

    _routingEngine.calculateScooterRoute(
        waypoints, routingOptions, calculateRouteCallback);
  }

  void returnToRouteWithTraveledDistance(
    HERE.Route route,
    HERE.Waypoint startingPoint,
    int lastTraveledSectionIndex,
    int traveledDistanceOnLastSectionInMeters,
    CalculateRouteCallback callback,
  ) {
    _routingEngine.returnToRouteWithTraveledDistance(
      route,
      startingPoint,
      lastTraveledSectionIndex,
      traveledDistanceOnLastSectionInMeters,
      callback,
    );
  }
}
