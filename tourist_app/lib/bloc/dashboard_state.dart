part of 'dashboard_bloc.dart';

@immutable
abstract class DashboardState {}

/// Initial state before any data is fetched.
class DashboardInitial extends DashboardState {}

/// State indicating that the data is currently being fetched from the backend.
/// The UI will show a loading spinner in this state.
class DashboardLoading extends DashboardState {}

/// State indicating that the dashboard data (safety score and itinerary) has been successfully loaded.
/// The UI will display the data from this state.
class DashboardLoaded extends DashboardState {
  final int safetyScore;
  final Map<String, dynamic> itinerary;

  DashboardLoaded({required this.safetyScore, required this.itinerary});
}

/// State indicating that an error occurred while fetching the data.
/// The UI will show an error message in this state.
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
