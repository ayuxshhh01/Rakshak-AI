part of 'location_bloc.dart';

@immutable
abstract class LocationEvent {}

/// Event to start listening for GPS location updates.
class StartLocationTracking extends LocationEvent {}

/// Internal event triggered when a new location is received.
class _LocationUpdated extends LocationEvent {
  final Position position;
  _LocationUpdated(this.position);
}