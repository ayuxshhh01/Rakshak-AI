part of 'trusted_circle_bloc.dart';

abstract class TrustedCircleState extends Equatable {
  const TrustedCircleState();

  @override
  List<Object> get props => [];
}

class TrustedCircleInitial extends TrustedCircleState {
  const TrustedCircleInitial();
}

class TrustedCircleLoading extends TrustedCircleState {
  const TrustedCircleLoading();
}

class TrustedCircleLoaded extends TrustedCircleState {
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> sharedLocations;

  const TrustedCircleLoaded({
    required this.members,
    required this.sharedLocations,
  });

  @override
  List<Object> get props => [members, sharedLocations];
}

class TrustedCircleError extends TrustedCircleState {
  final String message;

  const TrustedCircleError(this.message);

  @override
  List<Object> get props => [message];
}

class TrustedCircleSuccess extends TrustedCircleState {
  final String message;

  const TrustedCircleSuccess(this.message);

  @override
  List<Object> get props => [message];
}
