import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/listening_provider.dart';
import '../widgets/listening_set_card.dart';

class ListeningSetListScreen extends ConsumerStatefulWidget {
  const ListeningSetListScreen({super.key});

  @override
  ConsumerState<ListeningSetListScreen> createState() => _ListeningSetListScreenState();
}

class _ListeningSetListScreenState extends ConsumerState<ListeningSetListScreen> {
  int? _selectedPart;

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(listeningSetsProvider(_selectedPart));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Luyện Nghe TOEIC', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.lightSurface,
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: AppColors.lightSurface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả Part', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Part 1 (Hình ảnh)', 1),
                  const SizedBox(width: 8),
                  _buildFilterChip('Part 2 (Hỏi - Đáp)', 2),
                  const SizedBox(width: 8),
                  _buildFilterChip('Part 3 (Hội thoại)', 3),
                  const SizedBox(width: 8),
                  _buildFilterChip('Part 4 (Bài nói)', 4),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBorder),

          // Main List View
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.refresh(listeningSetsProvider(_selectedPart));
              },
              child: setsAsync.when(
                data: (sets) {
                  if (sets.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.headphones_outlined, size: 72, color: AppColors.lightTextSecondary),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có bài luyện nghe nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Thử thay đổi bộ lọc hoặc quay lại sau.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sets.length,
                    itemBuilder: (context, index) {
                      final set = sets[index];
                      return ListeningSetCard(
                        set: set,
                        onTap: () {
                          context.push('/listening/play/${set.id}');
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Lỗi tải danh sách bài nghe: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? part) {
    final isSelected = _selectedPart == part;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedPart = part;
            });
          }
        },
        selectedColor: AppColors.brandPrimary,
        backgroundColor: AppColors.lightSurfaceAlt,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
