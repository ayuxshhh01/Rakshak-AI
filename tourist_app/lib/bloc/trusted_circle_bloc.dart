import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../api/api_service.dart';

part 'trusted_circle_event.dart';
part 'trusted_circle_state.dart';

class TrustedCircleBloc extends Bloc<TrustedCircleEvent, TrustedCircleState> {
  final ApiService apiService;

  TrustedCircleBloc({required this.apiService}) : super(const TrustedCircleInitial()) {
    on<FetchTrustedCircle>(_onFetchTrustedCircle);
    on<AddTrustedCircleMember>(_onAddMember);
    on<DeleteTrustedCircleMember>(_onDeleteMember);
    on<FetchSharedLocations>(_onFetchSharedLocations);
  }

  Future<void> _onFetchTrustedCircle(FetchTrustedCircle event, Emitter<TrustedCircleState> emit) async {
    emit(const TrustedCircleLoading());
    try {
      final members = await apiService.getTrustedCircle();
      final locations = await apiService.getSharedLocations();
      emit(TrustedCircleLoaded(members: members, sharedLocations: locations));
    } catch (e) {
      emit(TrustedCircleError(e.toString()));
    }
  }

  Future<void> _onAddMember(AddTrustedCircleMember event, Emitter<TrustedCircleState> emit) async {
    emit(const TrustedCircleLoading());
    try {
      await apiService.addTrustedCircleMember(
        event.name,
        event.phoneNumber,
        event.relationship,
      );
      final members = await apiService.getTrustedCircle();
      final locations = await apiService.getSharedLocations();
      emit(TrustedCircleLoaded(members: members, sharedLocations: locations));
      emit(const TrustedCircleSuccess('Member added successfully'));
    } catch (e) {
      emit(TrustedCircleError(e.toString()));
    }
  }

  Future<void> _onDeleteMember(DeleteTrustedCircleMember event, Emitter<TrustedCircleState> emit) async {
    try {
      await apiService.deleteTrustedCircleMember(event.memberId);
      final members = await apiService.getTrustedCircle();
      final locations = await apiService.getSharedLocations();
      emit(TrustedCircleLoaded(members: members, sharedLocations: locations));
      emit(const TrustedCircleSuccess('Member removed'));
    } catch (e) {
      emit(TrustedCircleError(e.toString()));
    }
  }

  Future<void> _onFetchSharedLocations(FetchSharedLocations event, Emitter<TrustedCircleState> emit) async {
    try {
      final locations = await apiService.getSharedLocations();
      final members = await apiService.getTrustedCircle();
      emit(TrustedCircleLoaded(members: members, sharedLocations: locations));
    } catch (e) {
      emit(TrustedCircleError(e.toString()));
    }
  }
}
