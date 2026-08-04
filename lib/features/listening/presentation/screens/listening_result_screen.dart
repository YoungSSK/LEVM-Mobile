import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/listening_models.dart';
import '../widgets/listening_transcript_sheet.dart';

class ListeningResultScreen extends StatefulWidget {
  final ListeningSubmitResult result;

  const ListeningResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<ListeningResultScreen> createState() => _ListeningResultScreenState();
}

class _ListeningResultScreenState extends State<ListeningResultScreen> {
  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isPassed = result.isPassed;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Kết Quả Luyện Nghe', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.lightSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score Summary Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPassed
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isPassed ? Colors.green : Colors.red).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPassed ? 'HOÀN THÀNH BÀI NGHE!' : 'CHƯA ĐẠT YÊU CẦU',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.score}%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Đúng ${result.correctAnswers}/${result.totalQuestions} câu hỏi',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),

                  if (result.xpEarned > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.black87, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Thưởng +${result.xpEarned} XP',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chi tiết bài làm & Transcript:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Detail answers list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.details.length,
              itemBuilder: (context, idx) {
                final detail = result.details[idx];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Status Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: detail.isCorrect ? AppColors.success : AppColors.danger,
                            ),
                            child: Icon(
                              detail.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Câu ${idx + 1}: ${detail.questionText ?? "Mô tả ảnh / Hỏi đáp"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Selected vs Correct Key
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'Bạn chọn: ${detail.selectedKey.isEmpty ? "Bỏ trống" : detail.selectedKey}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: detail.isCorrect ? AppColors.success : AppColors.danger,
                              ),
                            ),
                            Text(
                              'Đáp án đúng: ${detail.correctKey}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Explanation if present
                      if (detail.explanation.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  detail.explanation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightTextPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Expandable Transcript Component
                      if (detail.transcript.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ListeningTranscriptSheet(transcript: detail.transcript),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Quay Về Danh Sách Bài Nghe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
