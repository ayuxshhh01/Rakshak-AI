import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api/api_service.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  StreamSubscription<Position>? _positionStream;
  final ApiService apiService;

  LocationBloc({required this.apiService}) : super(LocationInitial()) {
    on<StartLocationTracking>((event, emit) async {
      emit(LocationLoading());
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          emit(LocationError('GPS is disabled. Please enable location services.'));
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
            emit(LocationError('Location permission was denied.'));
            return;
          }
        }

        _positionStream?.cancel();
        _positionStream = Geolocator.getPositionStream().listen((Position position) {
          add(_LocationUpdated(position));
        });
      } catch (e) {
        emit(LocationError(e.toString()));
      }
    });

    on<_LocationUpdated>((event, emit) {
      emit(LocationAcquired(event.position));

      // --- THIS IS THE FIX ---
      // We now pass the altitude along with the latitude and longitude.
      apiService.updateLocation(
          event.position.latitude,
          event.position.longitude,
          event.position.altitude
      );
    });
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    return super.close();
  }
}

