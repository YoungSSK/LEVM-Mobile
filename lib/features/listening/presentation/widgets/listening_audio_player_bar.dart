import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_colors.dart';

class ListeningAudioPlayerBar extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final String title;

  const ListeningAudioPlayerBar({
    super.key,
    required this.audioPlayer,
    this.title = 'Phát bài nghe',
  });

  @override
  State<ListeningAudioPlayerBar> createState() => _ListeningAudioPlayerBarState();
}

class _ListeningAudioPlayerBarState extends State<ListeningAudioPlayerBar> {
  double _currentSpeed = 1.0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _listenToPlayerStreams();
  }

  void _listenToPlayerStreams() {
    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    widget.audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    widget.audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() {
          _duration = dur;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds.toDouble();
    final validMax = maxMs > 0 ? maxMs : 100.0;
    final validPos = posMs.clamp(0.0, validMax);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title & Speed Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.headphones_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Speed Selector Button
              InkWell(
                onTap: _cycleSpeed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentSpeed}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Slider & Duration Labels
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.amber,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 3,
            ),
            child: Slider(
              min: 0.0,
              max: validMax,
              value: validPos,
              onChanged: (value) {
                try {
                  widget.audioPlayer.seek(Duration(milliseconds: value.round()));
                } catch (_) {}
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Playback Controls (Replay 5s, Play/Pause, Forward 5s)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 26,
                icon: const Icon(Icons.replay_5_rounded, color: Colors.white),
                onPressed: () {
                  try {
                    final current = widget.audioPlayer.position;
                    widget.audioPlayer.seek(current - const Duration(seconds: 5));
                  } catch (_) {}
                },
              ),
              const SizedBox(width: 16),

              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black87,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(width: 16),
              IconButton(
                iconSize: 26,
                icon: const Icon(Icons.forward_5_rounded, color: Colors.white),
                onPressed: () {
                  try {
                    final current = widget.audioPlayer.position;
                    widget.audioPlayer.seek(current + const Duration(seconds: 5));
                  } catch (_) {}
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _cycleSpeed() {
    double nextSpeed = 1.0;
    if (_currentSpeed == 1.0) {
      nextSpeed = 1.2;
    } else if (_currentSpeed == 1.2) {
      nextSpeed = 1.5;
    } else if (_currentSpeed == 1.5) {
      nextSpeed = 0.8;
    } else {
      nextSpeed = 1.0;
    }

    setState(() {
      _currentSpeed = nextSpeed;
    });

    try {
      widget.audioPlayer.setSpeed(nextSpeed);
    } catch (_) {}
  }

  void _togglePlay() {
    try {
      if (_isPlaying) {
        widget.audioPlayer.pause();
      } else {
        widget.audioPlayer.play();
      }
    } catch (_) {}
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
