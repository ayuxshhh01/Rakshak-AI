part of 'location_bloc.dart';

@immutable
abstract class LocationState {}

/// Initial state, before location tracking has started.
class LocationInitial extends LocationState {}

/// State indicating the app is actively trying to acquire a location.
/// The UI will show a loading indicator when in this state.
class LocationLoading extends LocationState {}

/// State indicating a stable GPS location has been acquired.
/// The UI will use the position from this state to update the map.
class LocationAcquired extends LocationState {
  final Position position;
  LocationAcquired(this.position);
}

/// State indicating an error occurred while getting the location.
/// The UI will show an error message when in this state.
class LocationError extends LocationState {
  final String message;
  LocationError(this.message);
}

