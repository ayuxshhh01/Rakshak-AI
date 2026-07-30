part of 'voice_sos_bloc.dart';
@immutable
abstract class VoiceSosState {}

/// The initial state, where the service is idle.
class VoiceSosIdle extends VoiceSosState {}

/// State indicating the app is actively listening for the keyword.
class VoiceSosListening extends VoiceSosState {}

/// A temporary state indicating that a voice alert has been successfully triggered.
class VoiceSosTriggered extends VoiceSosState {}

