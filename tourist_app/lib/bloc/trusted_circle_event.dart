part of 'trusted_circle_bloc.dart';

abstract class TrustedCircleEvent extends Equatable {
  const TrustedCircleEvent();

  @override
  List<Object> get props => [];
}

class FetchTrustedCircle extends TrustedCircleEvent {
  const FetchTrustedCircle();
}

class AddTrustedCircleMember extends TrustedCircleEvent {
  final String name;
  final String phoneNumber;
  final String relationship;

  const AddTrustedCircleMember({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  @override
  List<Object> get props => [name, phoneNumber, relationship];
}

class DeleteTrustedCircleMember extends TrustedCircleEvent {
  final int memberId;

  const DeleteTrustedCircleMember(this.memberId);

  @override
  List<Object> get props => [memberId];
}

class FetchSharedLocations extends TrustedCircleEvent {
  const FetchSharedLocations();
}
