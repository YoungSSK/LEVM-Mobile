import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/listening_provider.dart';
import 'listening_part1_screen.dart';
import 'listening_part2_screen.dart';
import 'listening_part34_screen.dart';
import 'listening_result_screen.dart';

class ListeningPlayScreen extends ConsumerStatefulWidget {
  final String setId;

  const ListeningPlayScreen({
    super.key,
    required this.setId,
  });

  @override
  ConsumerState<ListeningPlayScreen> createState() => _ListeningPlayScreenState();
}

class _ListeningPlayScreenState extends ConsumerState<ListeningPlayScreen> {
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    Future.microtask(() {
      ref.read(listeningSessionProvider.notifier).loadSession(widget.setId);
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _handleSubmit() async {
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    final result = await ref
        .read(listeningSessionProvider.notifier)
        .submitQuizWithDuration(elapsedSeconds);

    if (result != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ListeningResultScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(listeningSessionProvider);

    if (sessionState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Luyện nghe TOEIC')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (sessionState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Luyện nghe TOEIC')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  sessionState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(listeningSessionProvider.notifier).loadSession(widget.setId);
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final payload = sessionState.payload;
    if (payload == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Luyện nghe TOEIC')),
        body: const Center(child: Text('Không có dữ liệu bài nghe')),
      );
    }

    Widget content;
    switch (payload.set.part) {
      case 1:
        content = ListeningPart1Screen(payload: payload, onSubmit: _handleSubmit);
        break;
      case 2:
        content = ListeningPart2Screen(payload: payload, onSubmit: _handleSubmit);
        break;
      case 3:
      case 4:
        content = ListeningPart34Screen(payload: payload, onSubmit: _handleSubmit);
        break;
      default:
        content = ListeningPart1Screen(payload: payload, onSubmit: _handleSubmit);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('TOEIC Part ${payload.set.part}: ${payload.set.title}'),
      ),
      body: content,
    );
  }
}
