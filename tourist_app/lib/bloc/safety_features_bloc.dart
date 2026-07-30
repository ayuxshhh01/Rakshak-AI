import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../api/api_service.dart';

// ============= CHECK-IN BLOC =============
abstract class CheckInEvent extends Equatable {
  const CheckInEvent();
  @override
  List<Object> get props => [];
}

class FetchCheckIns extends CheckInEvent {
  const FetchCheckIns();
}

class CreateCheckIn extends CheckInEvent {
  final double lat, lon;
  final String locationName, status, note, visibility;

  const CreateCheckIn({
    required this.lat,
    required this.lon,
    required this.locationName,
    required this.status,
    required this.note,
    required this.visibility,
  });

  @override
  List<Object> get props => [lat, lon, locationName, status, note, visibility];
}

abstract class CheckInState extends Equatable {
  const CheckInState();
  @override
  List<Object> get props => [];
}

class CheckInInitial extends CheckInState {
  const CheckInInitial();
}

class CheckInLoading extends CheckInState {
  const CheckInLoading();
}

class CheckInLoaded extends CheckInState {
  final List<Map<String, dynamic>> checkIns;

  const CheckInLoaded(this.checkIns);

  @override
  List<Object> get props => [checkIns];
}

class CheckInError extends CheckInState {
  final String message;

  const CheckInError(this.message);

  @override
  List<Object> get props => [message];
}

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final ApiService apiService;

  CheckInBloc({required this.apiService}) : super(const CheckInInitial()) {
    on<FetchCheckIns>(_onFetch);
    on<CreateCheckIn>(_onCreate);
  }

  Future<void> _onFetch(FetchCheckIns event, Emitter<CheckInState> emit) async {
    emit(const CheckInLoading());
    try {
      final checkIns = await apiService.getCheckIns();
      emit(CheckInLoaded(checkIns));
    } catch (e) {
      emit(CheckInError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateCheckIn event, Emitter<CheckInState> emit) async {
    emit(const CheckInLoading());
    try {
      await apiService.createCheckIn(
        event.lat,
        event.lon,
        event.locationName,
        event.status,
        event.note,
        event.visibility,
      );
      final checkIns = await apiService.getCheckIns();
      emit(CheckInLoaded(checkIns));
    } catch (e) {
      emit(CheckInError(e.toString()));
    }
  }
}

// ============= AREA SAFETY BLOC =============
abstract class AreaSafetyEvent extends Equatable {
  const AreaSafetyEvent();
  @override
  List<Object> get props => [];
}

class FetchAreaSafety extends AreaSafetyEvent {
  final double? lat, lon, radius;

  const FetchAreaSafety({this.lat, this.lon, this.radius});

  @override
  List<Object> get props => [lat ?? 0, lon ?? 0, radius ?? 5];
}

abstract class AreaSafetyState extends Equatable {
  const AreaSafetyState();
  @override
  List<Object> get props => [];
}

class AreaSafetyInitial extends AreaSafetyState {
  const AreaSafetyInitial();
}

class AreaSafetyLoading extends AreaSafetyState {
  const AreaSafetyLoading();
}

class AreaSafetyLoaded extends AreaSafetyState {
  final List<Map<String, dynamic>> areas;

  const AreaSafetyLoaded(this.areas);

  @override
  List<Object> get props => [areas];
}

class AreaSafetyError extends AreaSafetyState {
  final String message;

  const AreaSafetyError(this.message);

  @override
  List<Object> get props => [message];
}

class AreaSafetyBloc extends Bloc<AreaSafetyEvent, AreaSafetyState> {
  final ApiService apiService;

  AreaSafetyBloc({required this.apiService}) : super(const AreaSafetyInitial()) {
    on<FetchAreaSafety>(_onFetch);
  }

  Future<void> _onFetch(FetchAreaSafety event, Emitter<AreaSafetyState> emit) async {
    emit(const AreaSafetyLoading());
    try {
      final areas = await apiService.getAreaSafetyRatings(
        lat: event.lat,
        lon: event.lon,
        radius: event.radius,
      );
      emit(AreaSafetyLoaded(areas));
    } catch (e) {
      emit(AreaSafetyError(e.toString()));
    }
  }
}

// ============= EMERGENCY NUMBERS BLOC =============
abstract class EmergencyNumberEvent extends Equatable {
  const EmergencyNumberEvent();
  @override
  List<Object> get props => [];
}

class FetchEmergencyNumbers extends EmergencyNumberEvent {
  final String? country, city, serviceType;

  const FetchEmergencyNumbers({this.country, this.city, this.serviceType});

  @override
  List<Object> get props => [country ?? '', city ?? '', serviceType ?? ''];
}

abstract class EmergencyNumberState extends Equatable {
  const EmergencyNumberState();
  @override
  List<Object> get props => [];
}

class EmergencyNumberInitial extends EmergencyNumberState {
  const EmergencyNumberInitial();
}

class EmergencyNumberLoading extends EmergencyNumberState {
  const EmergencyNumberLoading();
}

class EmergencyNumberLoaded extends EmergencyNumberState {
  final List<Map<String, dynamic>> numbers;

  const EmergencyNumberLoaded(this.numbers);

  @override
  List<Object> get props => [numbers];
}

class EmergencyNumberError extends EmergencyNumberState {
  final String message;

  const EmergencyNumberError(this.message);

  @override
  List<Object> get props => [message];
}

class EmergencyNumberBloc extends Bloc<EmergencyNumberEvent, EmergencyNumberState> {
  final ApiService apiService;

  EmergencyNumberBloc({required this.apiService}) : super(const EmergencyNumberInitial()) {
    on<FetchEmergencyNumbers>(_onFetch);
  }

  Future<void> _onFetch(FetchEmergencyNumbers event, Emitter<EmergencyNumberState> emit) async {
    emit(const EmergencyNumberLoading());
    try {
      final numbers = await apiService.getEmergencyNumbers(
        country: event.country,
        city: event.city,
        serviceType: event.serviceType,
      );
      emit(EmergencyNumberLoaded(numbers));
    } catch (e) {
      emit(EmergencyNumberError(e.toString()));
    }
  }
}

// ============= EMERGENCY PHRASES BLOC =============
abstract class EmergencyPhraseEvent extends Equatable {
  const EmergencyPhraseEvent();
  @override
  List<Object> get props => [];
}

class FetchEmergencyPhrases extends EmergencyPhraseEvent {
  final String language;

  const FetchEmergencyPhrases(this.language);

  @override
  List<Object> get props => [language];
}

abstract class EmergencyPhraseState extends Equatable {
  const EmergencyPhraseState();
  @override
  List<Object> get props => [];
}

class EmergencyPhraseInitial extends EmergencyPhraseState {
  const EmergencyPhraseInitial();
}

class EmergencyPhraseLoading extends EmergencyPhraseState {
  const EmergencyPhraseLoading();
}

class EmergencyPhraseLoaded extends EmergencyPhraseState {
  final List<Map<String, dynamic>> phrases;

  const EmergencyPhraseLoaded(this.phrases);

  @override
  List<Object> get props => [phrases];
}

class EmergencyPhraseError extends EmergencyPhraseState {
  final String message;

  const EmergencyPhraseError(this.message);

  @override
  List<Object> get props => [message];
}

class EmergencyPhraseBloc extends Bloc<EmergencyPhraseEvent, EmergencyPhraseState> {
  final ApiService apiService;

  EmergencyPhraseBloc({required this.apiService}) : super(const EmergencyPhraseInitial()) {
    on<FetchEmergencyPhrases>(_onFetch);
  }

  Future<void> _onFetch(FetchEmergencyPhrases event, Emitter<EmergencyPhraseState> emit) async {
    emit(const EmergencyPhraseLoading());
    try {
      final phrases = await apiService.getEmergencyPhrases(event.language);
      emit(EmergencyPhraseLoaded(phrases));
    } catch (e) {
      emit(EmergencyPhraseError(e.toString()));
    }
  }
}

// ============= INCIDENT REPORT BLOC =============
abstract class IncidentReportEvent extends Equatable {
  const IncidentReportEvent();
  @override
  List<Object> get props => [];
}

class FetchIncidentReports extends IncidentReportEvent {
  const FetchIncidentReports();
}

class ReportIncident extends IncidentReportEvent {
  final double lat, lon;
  final String locationName, incidentType, description, severity;

  const ReportIncident({
    required this.lat,
    required this.lon,
    required this.locationName,
    required this.incidentType,
    required this.description,
    required this.severity,
  });

  @override
  List<Object> get props => [lat, lon, locationName, incidentType, description, severity];
}

class LikeIncidentReport extends IncidentReportEvent {
  final int reportId;

  const LikeIncidentReport(this.reportId);

  @override
  List<Object> get props => [reportId];
}

abstract class IncidentReportState extends Equatable {
  const IncidentReportState();
  @override
  List<Object> get props => [];
}

class IncidentReportInitial extends IncidentReportState {
  const IncidentReportInitial();
}

class IncidentReportLoading extends IncidentReportState {
  const IncidentReportLoading();
}

class IncidentReportLoaded extends IncidentReportState {
  final List<Map<String, dynamic>> reports;

  const IncidentReportLoaded(this.reports);

  @override
  List<Object> get props => [reports];
}

class IncidentReportError extends IncidentReportState {
  final String message;

  const IncidentReportError(this.message);

  @override
  List<Object> get props => [message];
}

class IncidentReportBloc extends Bloc<IncidentReportEvent, IncidentReportState> {
  final ApiService apiService;

  IncidentReportBloc({required this.apiService}) : super(const IncidentReportInitial()) {
    on<FetchIncidentReports>(_onFetch);
    on<ReportIncident>(_onReport);
    on<LikeIncidentReport>(_onLike);
  }

  Future<void> _onFetch(FetchIncidentReports event, Emitter<IncidentReportState> emit) async {
    emit(const IncidentReportLoading());
    try {
      final reports = await apiService.getIncidentReports();
      emit(IncidentReportLoaded(reports));
    } catch (e) {
      emit(IncidentReportError(e.toString()));
    }
  }

  Future<void> _onReport(ReportIncident event, Emitter<IncidentReportState> emit) async {
    emit(const IncidentReportLoading());
    try {
      await apiService.reportIncident(
        event.lat,
        event.lon,
        event.locationName,
        event.incidentType,
        event.description,
        event.severity,
      );
      final reports = await apiService.getIncidentReports();
      emit(IncidentReportLoaded(reports));
    } catch (e) {
      emit(IncidentReportError(e.toString()));
    }
  }

  Future<void> _onLike(LikeIncidentReport event, Emitter<IncidentReportState> emit) async {
    try {
      await apiService.likeIncidentReport(event.reportId);
      final reports = await apiService.getIncidentReports();
      emit(IncidentReportLoaded(reports));
    } catch (e) {
      emit(IncidentReportError(e.toString()));
    }
  }
}
