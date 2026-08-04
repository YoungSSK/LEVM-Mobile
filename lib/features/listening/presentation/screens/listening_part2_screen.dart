import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/listening_provider.dart';
import '../../domain/models/listening_models.dart';
import '../widgets/listening_audio_player_bar.dart';

class ListeningPart2Screen extends ConsumerStatefulWidget {
  final ListeningPlayPayload payload;
  final VoidCallback onSubmit;

  const ListeningPart2Screen({
    super.key,
    required this.payload,
    required this.onSubmit,
  });

  @override
  ConsumerState<ListeningPart2Screen> createState() => _ListeningPart2ScreenState();
}

class _ListeningPart2ScreenState extends ConsumerState<ListeningPart2Screen> {
  late AudioPlayer _audioPlayer;
  String? _lastLoadedAudioUrl;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadAudioForCurrentQuestion();
  }

  @override
  void didUpdateWidget(covariant ListeningPart2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadAudioForCurrentQuestion();
  }

  void _loadAudioForCurrentQuestion() async {
    final sessionState = ref.read(listeningSessionProvider);
    final questions = widget.payload.questions;
    if (questions.isEmpty) return;

    final safeIndex = sessionState.currentQuestionIndex.clamp(0, questions.length - 1);
    final currentQ = questions[safeIndex];

    if (currentQ.audioUrl != null &&
        currentQ.audioUrl!.isNotEmpty &&
        currentQ.audioUrl != _lastLoadedAudioUrl) {
      _lastLoadedAudioUrl = currentQ.audioUrl;
      try {
        await _audioPlayer.setUrl(currentQ.audioUrl!);
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(listeningSessionProvider);
    final questions = widget.payload.questions;

    if (questions.isEmpty) {
      return const Center(
        child: Text(
          'Bài nghe chưa có câu hỏi nào.',
          style: TextStyle(fontSize: 16, color: AppColors.lightTextSecondary),
        ),
      );
    }

    final currentIndex = sessionState.currentQuestionIndex.clamp(0, questions.length - 1);
    final currentQ = questions[currentIndex];
    final selectedKey = sessionState.selectedAnswers[currentQ.id];

    return Column(
      children: [
        // Question indicator header
        Container(
          color: AppColors.lightSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu hỏi ${currentIndex + 1} / ${questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const Text(
                    'Part 2 • Hỏi - Đáp',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (currentIndex + 1) / questions.length,
                  backgroundColor: AppColors.lightBorder,
                  color: AppColors.success,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Audio Player Control Card
                ListeningAudioPlayerBar(
                  audioPlayer: _audioPlayer,
                  title: 'Nghe câu hỏi và 3 câu trả lời (A, B, C)',
                ),

                const SizedBox(height: 32),

                // Part 2 Options A, B, C
                const Text(
                  'Chọn câu trả lời hợp lý nhất:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                Column(
                  children: ['A', 'B', 'C'].map((key) {
                    final isSelected = selectedKey == key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          ref.read(listeningSessionProvider.notifier).selectAnswer(currentQ.id, key);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.brandPrimary : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.brandPrimary : AppColors.lightBorder,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.brandPrimary.withOpacity(0.25)
                                    : Colors.black.withOpacity(0.03),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Đáp án ($key)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Navigation Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: currentIndex > 0
                    ? () {
                        ref.read(listeningSessionProvider.notifier).setQuestionIndex(currentIndex - 1);
                        _loadAudioForCurrentQuestion();
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                label: const Text('Câu trước'),
              ),
              if (currentIndex == questions.length - 1)
                ElevatedButton.icon(
                  onPressed: widget.onSubmit,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Nộp Bài', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(listeningSessionProvider.notifier).setQuestionIndex(currentIndex + 1);
                    _loadAudioForCurrentQuestion();
                  },
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  label: const Text('Câu Tiếp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
