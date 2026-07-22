import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/vocabulary_models.dart';
import '../../providers/study_session_provider.dart';

class WordRecallScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const WordRecallScreen({super.key, required this.lessonId});

  @override
  ConsumerState<WordRecallScreen> createState() => _WordRecallScreenState();
}

class _WordRecallScreenState extends ConsumerState<WordRecallScreen> {
  late ConfettiController _confettiController;
  bool _isCorrect = false;
  bool _showResult = false;
  final Random _random = Random();

  // Per-slot state. Index i holds the pool-index of the letter placed there,
  // or -1 if the slot is empty. Using a stable pool-index lets us return the
  // exact letter to its original position (even when the same character
  // appears multiple times, e.g. two "L"s).
  final List<int> _slotPoolIndex = <int>[];

  // Pool of available letters to pick from. Each letter has a stable index.
  final List<String> _letterPool = <String>[];
  final List<bool> _isUsed = <bool>[];

  // Track which word we initialized state for so we can reset on word change.
  PoolInit? _cachedPool;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studySessionProvider.notifier).loadLesson(widget.lessonId, 2);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(studySessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ghép từ"),
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
                AppColors.xp,
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
                ref.read(studySessionProvider.notifier).loadLesson(widget.lessonId, 2);
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

    return _buildWordRecallView(context, state, word);
  }

  Widget _buildWordRecallView(BuildContext context, StudySessionState state, StudyWordModel word) {
    _ensureInitializedForWord(word);

    return Column(
      children: [
        LinearProgressIndicator(
          value: (state.currentWordIndex + 1) / state.totalWords,
          backgroundColor: AppColors.warning.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation(AppColors.warning),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        word.meaning,
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          word.exampleSentence!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).hintColor,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildAnswerSlots(),
                const SizedBox(height: 32),
                if (!_showResult) _buildLetterGrid(),
                if (_showResult) _buildResultFeedback(),
                const Spacer(),
              ],
            ),
          ),
        ),
        _buildBottomActions(context, state, word),
      ],
    );
  }

  /// Build the empty/occupied answer slots. Each slot shows the letter the
  /// user placed there, or nothing when empty. We never pre-fill the correct
  /// answer — slots start blank.
  Widget _buildAnswerSlots() {
    final slotCount = _slotPoolIndex.length;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(slotCount, (slotIndex) {
        final poolIndex = _slotPoolIndex[slotIndex];
        final hasLetter = poolIndex >= 0;
        final letter = hasLetter ? _letterPool[poolIndex] : '';

        return GestureDetector(
          onTap: hasLetter && !_showResult ? () => _removeLetterAtSlot(slotIndex) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              color: _showResult
                  ? (_isCorrect
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.danger.withValues(alpha: 0.2))
                  : hasLetter
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showResult
                    ? (_isCorrect ? AppColors.success : AppColors.danger)
                    : AppColors.warning,
                width: 2,
              ),
            ),
            child: Center(
              child: hasLetter
                  ? Text(
                      letter,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _showResult && !_isCorrect
                            ? AppColors.danger
                            : null,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      }),
    );
  }

  /// Build the row of selectable letter tiles. Tiles whose pool-index is
  /// marked as used are hidden (opacity 0 + IgnorePointer) so the user can
  /// clearly see which letters remain available.
  Widget _buildLetterGrid() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_letterPool.length, (poolIndex) {
        final isUsed = _isUsed[poolIndex];
        return _LetterTile(
          letter: _letterPool[poolIndex],
          isUsed: isUsed,
          onTap: isUsed || _showResult ? null : () => _selectLetterAtPool(poolIndex),
        );
      }),
    );
  }

  Widget _buildResultFeedback() {
    return Column(
      children: [
        Icon(
          _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 64,
          color: _isCorrect ? AppColors.success : AppColors.danger,
        ),
        const SizedBox(height: 16),
        Text(
          _isCorrect ? "Chính xác!" : "Chưa đúng rồi",
          style: AppTypography.titleLarge.copyWith(
            color: _isCorrect ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, StudySessionState state, StudyWordModel word) {
    final allFilled = _slotPoolIndex.every((i) => i >= 0);

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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showResult
                    ? () => _nextWord(state)
                    : _canClear
                        ? _clearSelection
                        : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_showResult ? "Tiếp tục" : "Xóa"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (!_showResult)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: allFilled ? () => _checkAnswer(word) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Kiểm tra"),
                ),
              ),
            if (_showResult)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _nextWord(state),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text("Tiếp tục"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
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

  /// Initialize / reset the per-word state whenever the current word changes.
  /// The pool is generated ONCE per word (lazy + cached) so that rebuilds
  /// don't re-shuffle and clobber the user's selections.
  void _ensureInitializedForWord(StudyWordModel word) {
    if (_cachedPool != null &&
        _cachedPool!.wordId == word.wordId &&
        _cachedPool!.wordLength == word.word.length) {
      return;
    }

    final pool = _buildShuffledPool(word.word);

    _letterPool
      ..clear()
      ..addAll(pool);
    _isUsed
      ..clear()
      ..addAll(List<bool>.filled(pool.length, false));
    _slotPoolIndex
      ..clear()
      ..addAll(List<int>.filled(word.word.length, -1));

    _isCorrect = false;
    _showResult = false;

    _cachedPool = PoolInit(wordId: word.wordId, wordLength: word.word.length);
  }

  /// Build a shuffled letter pool containing exactly the letters of [word]
  /// (uppercased) plus enough random distractor letters so the user has a
  /// reasonable number of choices.
  List<String> _buildShuffledPool(String word) {
    final correctLetters = word.toUpperCase().split('');
    final distractors = _generateDistractors(correctLetters.length);
    final pool = <String>[...correctLetters, ...distractors]..shuffle(_random);
    return pool;
  }

  List<String> _generateDistractors(int correctCount) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    // Aim for roughly 6–10 total tiles, with at least 2 distractors for
    // short words and more for longer ones.
    final desiredTotal = max(6, correctCount + 2);
    final needed = max(2, desiredTotal - correctCount);
    final picked = <String>{};
    final result = <String>[];

    while (result.length < needed) {
      final letter = alphabet[_random.nextInt(alphabet.length)];
      if (picked.add(letter)) {
        result.add(letter);
      }
    }

    return result;
  }

  void _selectLetterAtPool(int poolIndex) {
    if (_showResult) return;
    if (poolIndex < 0 || poolIndex >= _isUsed.length) return;
    if (_isUsed[poolIndex]) return;

    final emptySlot = _slotPoolIndex.indexOf(-1);
    if (emptySlot < 0) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isUsed[poolIndex] = true;
      _slotPoolIndex[emptySlot] = poolIndex;
    });
  }

  void _removeLetterAtSlot(int slotIndex) {
    if (_showResult) return;
    if (slotIndex < 0 || slotIndex >= _slotPoolIndex.length) return;

    final poolIndex = _slotPoolIndex[slotIndex];
    if (poolIndex < 0) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isUsed[poolIndex] = false;
      _slotPoolIndex[slotIndex] = -1;
    });
  }

  bool get _canClear =>
      !_showResult && _slotPoolIndex.any((i) => i >= 0);

  void _clearSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var i = 0; i < _isUsed.length; i++) {
        _isUsed[i] = false;
      }
      for (var i = 0; i < _slotPoolIndex.length; i++) {
        _slotPoolIndex[i] = -1;
      }
    });
  }

  void _checkAnswer(StudyWordModel word) {
    final answer = _buildAnswerString(word);
    final isCorrect = answer.toLowerCase() == word.word.toLowerCase();

    HapticFeedback.mediumImpact();

    setState(() {
      _isCorrect = isCorrect;
      _showResult = true;
    });

    ref.read(studySessionProvider.notifier).submitAnswer(
          wordId: word.wordId,
          userAnswer: answer,
          isCorrect: isCorrect,
        );

    if (isCorrect) {
      _confettiController.play();
    }
  }

  /// Build the answer string from the slots in left-to-right order. Falls back
  /// to "" if a slot is somehow empty (should not happen because the button
  /// is disabled in that case).
  String _buildAnswerString(StudyWordModel word) {
    final buf = StringBuffer();
    for (var i = 0; i < _slotPoolIndex.length; i++) {
      final poolIndex = _slotPoolIndex[i];
      if (poolIndex < 0) {
        return '';
      }
      // i should always be < word.word.length by construction; clamp anyway.
      if (i < word.word.length) {
        buf.write(_letterPool[poolIndex]);
      }
    }
    return buf.toString();
  }

  void _nextWord(StudySessionState state) {
    setState(() {
      _resetSelectionState();
    });

    ref.read(studySessionProvider.notifier).nextWord();
  }

  void _resetSelectionState() {
    _cachedPool = null;
    _letterPool.clear();
    _isUsed.clear();
    _slotPoolIndex.clear();
    _isCorrect = false;
    _showResult = false;
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
              "Bạn đã ghép ${state.totalWords} từ",
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$score%",
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "$correctCount/$totalCount đúng",
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.warning,
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

class _LetterTile extends StatelessWidget {
  final String letter;
  final bool isUsed;
  final VoidCallback? onTap;

  const _LetterTile({
    required this.letter,
    required this.isUsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Used tiles stay laid out (so the rest of the grid doesn't jump) but
    // become invisible and non-interactive. Wrapping with IgnorePointer keeps
    // the tile from receiving taps while preserving its space.
    return IgnorePointer(
      ignoring: isUsed || onTap == null,
      child: Opacity(
        opacity: isUsed ? 0.0 : 1.0,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight value object used to detect whether the current word's pool
/// has already been generated. Stored as state so we never re-shuffle during
/// rebuilds — re-shuffling on every build would wipe the user's selections.
class PoolInit {
  final String wordId;
  final int wordLength;

  const PoolInit({required this.wordId, required this.wordLength});
}
