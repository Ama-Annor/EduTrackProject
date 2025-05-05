// File: lib/screens/widgets/audio_recorder_widget.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String audioPath, String audioUrl) onAudioSaved;

  const AudioRecorderWidget({Key? key, required this.onAudioSaved}) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _hasRecordingCompleted = false; // Add this to track when recording completes
  String _recordingPath = '';
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      await _initRecorder();
    }

    final directory = await getTemporaryDirectory();
    _recordingPath = '${directory.path}/audio_note_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
      _hasRecordingCompleted = false; // Reset this flag when starting a new recording
      _recordingDuration = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  Future<void> _stopRecording() async {
    final finalDuration = _recordingDuration; // Store final duration
    await _recorder.stopRecorder();
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _hasRecordingCompleted = true; // Set this flag to true when recording completes
      _recordingDuration = finalDuration; // Keep the final duration
    });

    // Upload the audio file
    await _uploadAudio();
  }

  Future<void> _uploadAudio() async {
    try {
      String fileName = 'audio_note_${DateTime.now().millisecondsSinceEpoch}.aac';
      Reference ref = FirebaseStorage.instance.ref().child('note_audios/$fileName');
      await ref.putFile(File(_recordingPath));
      String downloadURL = await ref.getDownloadURL();

      // Call the callback with local path and download URL
      widget.onAudioSaved(_recordingPath, downloadURL);
    } catch (e) {
      print('Error uploading audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(45, 45, 45, 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: const Color(0xFF00BFA5),
              size: 32,
            ),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          const SizedBox(width: 16),
          if (_isRecording || _hasRecordingCompleted)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isRecording ? 'Recording...' : 'Recording completed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Tap to record audio',
              style: TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }
}