import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flip_card/flip_card.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/vocabulary_models.dart';
import '../../providers/study_session_provider.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const FlashcardScreen({super.key, required this.lessonId});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studySessionProvider.notifier).loadLesson(widget.lessonId, 1);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(studySessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ghi nhớ từ vựng"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        actions: [
          if (sessionState.studyData != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  "${sessionState.currentWordIndex + 1}/${sessionState.totalWords}",
                  style: AppTypography.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, sessionState),
    );
  }

  Widget _buildBody(BuildContext context, StudySessionState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text("Lỗi: ${state.error}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(studySessionProvider.notifier).loadLesson(widget.lessonId, 1);
              },
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }

    if (state.studyData == null || state.studyData!.words.isEmpty) {
      return const Center(child: Text("Không có từ nào để học"));
    }

    if (!state.hasMoreWords && state.answers.isNotEmpty) {
      return _buildCompletionView(context, state);
    }

    final word = state.currentWord;
    if (word == null) {
      return _buildCompletionView(context, state);
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: (state.currentWordIndex + 1) / state.totalWords,
          backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation(AppColors.brandPrimary),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _FlashcardWidget(
              key: ValueKey(word.wordId),
              word: word,
              onPlayAudio: _playAudio,
              isPlaying: _isPlaying,
            ),
          ),
        ),
        _buildBottomActions(context, state, word),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, StudySessionState state, StudyWordModel word) {
    final isAnswered = state.answers.containsKey(word.wordId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.currentWordIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToPreviousWord(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text("Quay lại"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (state.currentWordIndex > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isAnswered
                    ? () => _handleContinue(context, state)
                    : () => _markAsKnown(context, word),
                icon: Icon(isAnswered ? Icons.arrow_forward_rounded : Icons.check_rounded),
                label: Text(isAnswered ? "Tiếp tục" : "Đã nhớ"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnswered ? AppColors.brandPrimary : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionView(BuildContext context, StudySessionState state) {
    final correctCount = state.answers.values.where((a) => a.isCorrect).length;
    final totalCount = state.answers.length;
    final score = totalCount > 0 ? ((correctCount / totalCount) * 100).round() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.brandGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Hoàn thành!",
              style: AppTypography.displayMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Bạn đã học ${state.totalWords} từ",
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$score%",
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "$correctCount/$totalCount đúng",
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _completeLevel(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Hoàn thành cấp độ"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playAudio(StudyWordModel word) async {
    if (_isPlaying) return;

    final audioUrl = word.audioUrls.us.isNotEmpty
        ? word.audioUrls.us
        : word.audioUrls.uk.isNotEmpty
            ? word.audioUrls.uk
            : null;

    if (audioUrl == null || audioUrl.isEmpty) return;

    setState(() => _isPlaying = true);

    try {
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint("Error playing audio: $e");
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  void _markAsKnown(BuildContext context, StudyWordModel word) {
    HapticFeedback.lightImpact();
    ref.read(studySessionProvider.notifier).submitAnswer(
          wordId: word.wordId,
          userAnswer: word.word,
          isCorrect: true,
        );
  }

  void _goToNextWord() {
    final state = ref.read(studySessionProvider);
    if (state.currentWordIndex < state.totalWords - 1) {
      ref.read(studySessionProvider.notifier).nextWord();
    }
  }

  void _goToPreviousWord() {
    final state = ref.read(studySessionProvider);
    if (state.currentWordIndex > 0) {
      ref.read(studySessionProvider.notifier).previousWord();
    }
  }

  Future<void> _handleContinue(BuildContext context, StudySessionState state) async {
    final isLastWord = state.currentWordIndex >= state.totalWords - 1;

    if (isLastWord) {
      await _completeLevel(context);
    } else {
      _goToNextWord();
    }
  }

  Future<void> _completeLevel(BuildContext context) async {
    final result = await ref.read(studySessionProvider.notifier).completeLevel();
    if (result != null && mounted) {
      context.go("/vocabulary/result/${result.attempt.id}");
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thoát bài học?"),
        content: const Text("Tiến độ học sẽ không được lưu."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text("Thoát"),
          ),
        ],
      ),
    );
  }
}

class _FlashcardWidget extends StatelessWidget {
  final StudyWordModel word;
  final Function(StudyWordModel) onPlayAudio;
  final bool isPlaying;

  const _FlashcardWidget({
    super.key,
    required this.word,
    required this.onPlayAudio,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      direction: FlipDirection.HORIZONTAL,
      speed: 400,
      front: _buildFront(context),
      back: _buildBack(context),
    );
  }

  Widget _buildFront(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: isPlaying ? null : () => onPlayAudio(word),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                  key: ValueKey(isPlaying),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word.word,
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (word.pronunciations.us.isNotEmpty)
                  Text(
                    "/${word.pronunciations.us}/",
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    word.displayPartOfSpeech,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Chạm để lật",
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  word.displayPartOfSpeech,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                word.meaning,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.brandPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        word.exampleSentence!,
                        style: AppTypography.bodyMedium.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.brandPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (word.exampleMeaning != null && word.exampleMeaning!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          word.exampleMeaning!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
