import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../api/api_service.dart';

// ============= SAFE ROUTE BLOC =============
abstract class SafeRouteEvent extends Equatable {
  const SafeRouteEvent();
  @override
  List<Object> get props => [];
}

class FetchSafeRoutes extends SafeRouteEvent {
  const FetchSafeRoutes();
}

class GenerateSafeRoute extends SafeRouteEvent {
  final double startLat, startLon, endLat, endLon;
  final String routeName;

  const GenerateSafeRoute({
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.routeName,
  });

  @override
  List<Object> get props => [startLat, startLon, endLat, endLon, routeName];
}

abstract class SafeRouteState extends Equatable {
  const SafeRouteState();
  @override
  List<Object> get props => [];
}

class SafeRouteInitial extends SafeRouteState {
  const SafeRouteInitial();
}

class SafeRouteLoading extends SafeRouteState {
  const SafeRouteLoading();
}

class SafeRouteLoaded extends SafeRouteState {
  final List<Map<String, dynamic>> routes;

  const SafeRouteLoaded(this.routes);

  @override
  List<Object> get props => [routes];
}

class SafeRouteError extends SafeRouteState {
  final String message;

  const SafeRouteError(this.message);

  @override
  List<Object> get props => [message];
}

class SafeRouteBloc extends Bloc<SafeRouteEvent, SafeRouteState> {
  final ApiService apiService;

  SafeRouteBloc({required this.apiService}) : super(const SafeRouteInitial()) {
    on<FetchSafeRoutes>(_onFetch);
    on<GenerateSafeRoute>(_onGenerate);
  }

  Future<void> _onFetch(FetchSafeRoutes event, Emitter<SafeRouteState> emit) async {
    emit(const SafeRouteLoading());
    try {
      final routes = await apiService.getSafeRoutes();
      emit(SafeRouteLoaded(routes));
    } catch (e) {
      emit(SafeRouteError(e.toString()));
    }
  }

  Future<void> _onGenerate(GenerateSafeRoute event, Emitter<SafeRouteState> emit) async {
    emit(const SafeRouteLoading());
    try {
      await apiService.generateSafeRoute(
        event.startLat,
        event.startLon,
        event.endLat,
        event.endLon,
        event.routeName,
      );
      final routes = await apiService.getSafeRoutes();
      emit(SafeRouteLoaded(routes));
    } catch (e) {
      emit(SafeRouteError(e.toString()));
    }
  }
}
