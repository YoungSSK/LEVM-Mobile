import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class VocabularyBottomSheet extends StatefulWidget {
  final String word;
  final Map<String, dynamic>? wordData;

  const VocabularyBottomSheet({
    super.key,
    required this.word,
    this.wordData,
  });

  static Future<void> show(BuildContext context, String word, [Map<String, dynamic>? wordData]) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VocabularyBottomSheet(word: word, wordData: wordData),
    );
  }

  @override
  State<VocabularyBottomSheet> createState() => _VocabularyBottomSheetState();
}

class _VocabularyBottomSheetState extends State<VocabularyBottomSheet> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanWord = widget.word.replaceAll(RegExp(r'[^\w]'), '');
    final ipa = widget.wordData?['ipa'] ?? '/${cleanWord.toLowerCase()}/';
    final partOfSpeech = widget.wordData?['partOfSpeech'] ?? 'Noun';
    final level = widget.wordData?['level'] ?? 'B2';
    final definition = widget.wordData?['definition'] ??
        'Định nghĩa và ý nghĩa chi tiết của từ "$cleanWord" trong tiếng Việt.';
    final example = widget.wordData?['example'] ??
        'This is a sample context sentence containing the word "$cleanWord".';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Word Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cleanWord,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "$partOfSpeech • $level",
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ipa,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // Speaker Audio Button
              IconButton.filledTonal(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đang phát âm từ "$cleanWord"...'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.brandPrimary),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Definition Section
          Text(
            "Nghĩa tiếng Việt",
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            definition,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Example Sentence
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, size: 18, color: AppColors.brandPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    example,
                    style: AppTypography.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Word CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isSaved = !_isSaved;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isSaved ? 'Đã lưu từ "$cleanWord" vào sổ từ vựng!' : 'Đã bỏ lưu từ.',
                    ),
                    backgroundColor: _isSaved ? AppColors.success : Colors.grey[700],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaved ? AppColors.success : AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: Icon(_isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded),
              label: Text(
                _isSaved ? 'Đã lưu từ vựng' : '+ Lưu vào sổ từ vựng',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
