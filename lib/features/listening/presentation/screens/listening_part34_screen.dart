import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/listening_provider.dart';
import '../../domain/models/listening_models.dart';
import '../widgets/listening_audio_player_bar.dart';

class ListeningPart34Screen extends ConsumerStatefulWidget {
  final ListeningPlayPayload payload;
  final VoidCallback onSubmit;

  const ListeningPart34Screen({
    super.key,
    required this.payload,
    required this.onSubmit,
  });

  @override
  ConsumerState<ListeningPart34Screen> createState() => _ListeningPart34ScreenState();
}

class _ListeningPart34ScreenState extends ConsumerState<ListeningPart34Screen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadGroupAudio();
  }

  void _loadGroupAudio() async {
    final groups = widget.payload.groups;
    if (groups.isNotEmpty && groups.first.audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(groups.first.audioUrl);
      } catch (_) {}
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

    return Column(
      children: [
        // Sticky Audio Player Control Header
        Padding(
          padding: const EdgeInsets.all(12),
          child: ListeningAudioPlayerBar(
            audioPlayer: _audioPlayer,
            title: 'Hội thoại Part ${widget.payload.set.part}',
          ),
        ),

        // Scrollable Questions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: questions.length,
            itemBuilder: (context, qIdx) {
              final q = questions[qIdx];
              final selectedKey = sessionState.selectedAnswers[q.id];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Câu ${qIdx + 1}',
                            style: const TextStyle(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q.questionText ?? "",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Choice options list
                    Column(
                      children: q.options.map((opt) {
                        final isSelected = selectedKey == opt.key;
                        return InkWell(
                          onTap: () {
                            ref
                                .read(listeningSessionProvider.notifier)
                                .selectAnswer(q.id, opt.key);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandPrimary.withOpacity(0.08)
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandPrimary
                                    : AppColors.lightBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.brandPrimary
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.brandPrimary
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      opt.key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSelected ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Submit Button Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppColors.lightSurface,
          child: ElevatedButton.icon(
            onPressed: widget.onSubmit,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text(
              'Nộp Bài Luyện Nghe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
