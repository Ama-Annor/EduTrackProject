import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({Key? key, required this.audioUrl}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlayerInitialized = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    _isPlayerInitialized = true;

    // Try to get the duration of the audio file
    try {
      // The getProgress method returns a different structure than expected
      // Let's modify how we handle it
      var progress = await _player.getProgress();
      if (progress != null) {
        setState(() {
          // Access the duration directly from the progress
          _duration = progress['duration'] as Duration? ?? Duration.zero;
        });
      }
    } catch (e) {
      print('Error getting audio duration: $e');
    }

    _durationSubscription = _player.onProgress?.listen((event) {
      setState(() {
        _duration = event.duration;
        _position = event.position;
      });
    });
  }

  Future<void> _playAudio() async {
    if (!_isPlayerInitialized) {
      await _initPlayer();
    }

    await _player.startPlayer(
        fromURI: widget.audioUrl,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
    );

    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _stopAudio() async {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
    });
  }

  Future<void> _pauseAudio() async {
    await _player.pausePlayer();
    setState(() {
      _isPlaying = false;
    });
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFF00BFA5),
                  size: 32,
                ),
                onPressed: _isPlaying ? _pauseAudio : _playAudio,
              ),
              IconButton(
                icon: const Icon(
                  Icons.stop,
                  color: Color(0xFF00BFA5),
                  size: 32,
                ),
                onPressed: _isPlaying ? _stopAudio : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Recording',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isPlaying || _position.inSeconds > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: LinearProgressIndicator(
                value: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0.0,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
              ),
            ),
        ],
      ),
    );
  }
}