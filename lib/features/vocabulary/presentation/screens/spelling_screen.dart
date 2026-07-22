import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:confetti/confetti.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/vocabulary_models.dart';
import '../../providers/study_session_provider.dart';

class SpellingScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const SpellingScreen({super.key, required this.lessonId});

  @override
  ConsumerState<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends ConsumerState<SpellingScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  bool _isPlaying = false;
  bool _showResult = false;
  bool _isCorrect = false;
  String _correctAnswer = '';
  int _playbackSpeed = 1;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // Rebuild whenever the text changes so the "Kiểm tra" button can enable
    // itself based on whether the user has typed anything.
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studySessionProvider.notifier).loadLesson(widget.lessonId, 3);
    });
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(studySessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chính tả"),
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
      body: Stack(
        children: [
          _buildBody(context, sessionState),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.danger,
                AppColors.success,
                AppColors.brandPrimary,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
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
                ref.read(studySessionProvider.notifier).loadLesson(widget.lessonId, 3);
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

    return _buildSpellingView(context, state, word);
  }

  Widget _buildSpellingView(BuildContext context, StudySessionState state, StudyWordModel word) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (state.currentWordIndex + 1) / state.totalWords,
          backgroundColor: AppColors.danger.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation(AppColors.danger),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),
                _buildAudioButton(word),
                const SizedBox(height: 32),
                if (word.pronunciations.us.isNotEmpty || word.pronunciations.uk.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      "/${word.pronunciations.us.isNotEmpty ? word.pronunciations.us : word.pronunciations.uk}/",
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildInputField(word),
                const SizedBox(height: 16),
                if (_showResult) _buildResultDisplay(word),
                const Spacer(),
              ],
            ),
          ),
        ),
        _buildBottomActions(context, state, word),
      ],
    );
  }

  Widget _buildAudioButton(StudyWordModel word) {
    final hasAudio = word.audioUrls.us.isNotEmpty || word.audioUrls.uk.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: hasAudio ? () => _playAudio(word) : null,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: hasAudio ? AppColors.danger : Colors.grey[400],
              shape: BoxShape.circle,
              boxShadow: hasAudio
                  ? [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Tốc độ:",
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(width: 8),
            _SpeedButton(
              label: "1x",
              isSelected: _playbackSpeed == 1,
              onTap: () => setState(() => _playbackSpeed = 1),
            ),
            const SizedBox(width: 8),
            _SpeedButton(
              label: "0.75x",
              isSelected: _playbackSpeed == 75,
              onTap: () => setState(() => _playbackSpeed = 75),
            ),
            const SizedBox(width: 8),
            _SpeedButton(
              label: "0.5x",
              isSelected: _playbackSpeed == 50,
              onTap: () => setState(() => _playbackSpeed = 50),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(StudyWordModel word) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showResult
              ? (_isCorrect ? AppColors.success : AppColors.danger)
              : Theme.of(context).dividerColor,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: !_showResult,
        autocorrect: false,
        textCapitalization: TextCapitalization.none,
        style: AppTypography.headlineSmall.copyWith(
          letterSpacing: 2,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: "Gõ từ ở đây...",
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).hintColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        onSubmitted: _showResult ? null : (_) => _checkAnswer(word),
      ),
    );
  }

  Widget _buildResultDisplay(StudyWordModel word) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: _isCorrect ? AppColors.success : AppColors.danger,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _isCorrect ? "Chính xác!" : "Chưa đúng rồi",
              style: AppTypography.titleMedium.copyWith(
                color: _isCorrect ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (!_isCorrect) ...[
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium,
              children: _buildDiffSpans(word.word, _textController.text),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Đáp án: ${word.word}",
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  List<TextSpan> _buildDiffSpans(String correct, String input) {
    final spans = <TextSpan>[];
    final inputLower = input.toLowerCase();
    final correctLower = correct.toLowerCase();

    for (var i = 0; i < correct.length; i++) {
      final isCorrectChar = i < inputLower.length && inputLower[i] == correctLower[i];
      spans.add(
        TextSpan(
          text: i < input.length ? input[i] : "_",
          style: AppTypography.headlineSmall.copyWith(
            color: isCorrectChar ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return spans;
  }

  Widget _buildBottomActions(BuildContext context, StudySessionState state, StudyWordModel word) {
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
                  onPressed: _showResult ? () => _nextWord(state) : null,
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
              child: ElevatedButton(
                onPressed: _showResult
                    ? () => _nextWord(state)
                    : _textController.text.isNotEmpty
                        ? () => _checkAnswer(word)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showResult ? AppColors.brandPrimary : AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_showResult ? "Tiếp tục" : "Kiểm tra"),
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
      await _audioPlayer.setSpeed(_playbackSpeed == 1 ? 1.0 : (_playbackSpeed / 100.0));
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

  Future<void> _checkAnswer(StudyWordModel word) async {
    final userAnswer = _textController.text.trim();
    if (userAnswer.isEmpty) return;

    setState(() {
      _showResult = true;
      _correctAnswer = word.word;
      _isCorrect = userAnswer.toLowerCase() == word.word.toLowerCase();
    });

    HapticFeedback.mediumImpact();

    ref.read(studySessionProvider.notifier).submitAnswer(
          wordId: word.wordId,
          userAnswer: userAnswer,
          isCorrect: _isCorrect,
        );

    if (_isCorrect) {
      _confettiController.play();
    }
  }

  void _nextWord(StudySessionState state) {
    setState(() {
      _textController.clear();
      _showResult = false;
      _isCorrect = false;
    });
    _focusNode.requestFocus();

    ref.read(studySessionProvider.notifier).nextWord();
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
              "Bạn đã kiểm tra chính tả ${state.totalWords} từ",
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$score%",
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "$correctCount/$totalCount đúng",
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.danger,
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

class _SpeedButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.danger.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.danger : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.danger : Theme.of(context).hintColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
