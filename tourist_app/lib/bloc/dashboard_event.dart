part of 'dashboard_bloc.dart';

@immutable
abstract class DashboardEvent {}

/// Event to trigger fetching data for the home screen (safety score and itinerary).
class FetchDashboardData extends DashboardEvent {}
