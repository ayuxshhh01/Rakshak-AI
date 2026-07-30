import 'dart:async';
import 'package:flutter/foundation.dart'; // <-- THIS IMPORT IS THE FIX
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geolocator/geolocator.dart';
import '../api/api_service.dart';

part 'voice_sos_event.dart';
part 'voice_sos_state.dart';

class VoiceSosBloc extends Bloc<VoiceSosEvent, VoiceSosState> {
  final ApiService apiService;
  final SpeechToText _speechToText = SpeechToText();

  int _helpCount = 0;
  Timer? _resetTimer;

  VoiceSosBloc({required this.apiService}) : super(VoiceSosIdle()) {
    on<StartListening>((event, emit) async {
      bool available = await _speechToText.initialize(
        onError: (error) => print("SpeechToText Error: $error"),
        onStatus: (status) => _statusListener(status),
      );
      if (available) {
        emit(VoiceSosListening());
        _startContinuousListening();
      } else {
        print("The user has denied the use of speech recognition.");
      }
    });

    on<_KeywordDetected>((event, emit) async {
      _resetTimer?.cancel();
      _helpCount++;
      print("Heard 'help' keyword. Count: $_helpCount");

      if (_helpCount >= 3) {
        print("--- TRIGGERING VOICE SOS ALERT ---");
        emit(VoiceSosTriggered());

        try {
          Position? position = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition();
          if (position != null) {
            await apiService.sendSosAlert(position.latitude, position.longitude);
          }
        } catch(e) {
          print("Could not get location for voice SOS: $e");
        }

        _helpCount = 0;
        emit(VoiceSosListening());
      } else {
        _resetTimer = Timer(const Duration(seconds: 10), () {
          print("Resetting help count due to timeout.");
          _helpCount = 0;
        });
      }
    });
  }

  void _statusListener(String status) {
    print("Speech listener status: $status");
    if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
      print("Listener stopped, restarting...");
      _startContinuousListening();
    }
  }

  void _startContinuousListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    _speechToText.listen(
      onResult: (result) {
        String recognizedWords = result.recognizedWords.toLowerCase();
        if (recognizedWords.contains("help")) {
          add(_KeywordDetected());
        }
      },
      listenFor: const Duration(hours: 30),
      pauseFor: const Duration(minutes: 3),
    );
  }

  @override
  Future<void> close() {
    _speechToText.stop();
    _resetTimer?.cancel();
    return super.close();
  }
}

