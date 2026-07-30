part of 'voice_sos_bloc.dart';

// The import statement has been removed as it's handled by the main BLoC file.
@immutable
abstract class VoiceSosEvent {}

/// Event to start listening for the voice keyword.
class StartListening extends VoiceSosEvent {}

/// Internal event triggered when the keyword "help" is detected.
class _KeywordDetected extends VoiceSosEvent {}

