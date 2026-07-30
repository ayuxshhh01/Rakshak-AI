import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../api/api_service.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService apiService;

  DashboardBloc({required this.apiService}) : super(DashboardInitial()) {
    on<FetchDashboardData>((event, emit) async {
      emit(DashboardLoading());
      try {
        final data = await apiService.getDashboardData();
        emit(DashboardLoaded(
          safetyScore: data['safety_score'],
          itinerary: data['itinerary'],
        ));
      } catch (e) {
        emit(DashboardError(e.toString()));
      }
    });
  }
}

