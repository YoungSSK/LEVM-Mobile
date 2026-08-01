import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../vocabulary/providers/xp_streak_provider.dart';
import '../../data/api/reading_api_service.dart';
import '../../domain/models/reading_category.dart';
import '../../domain/models/reading_passage.dart';
import '../widgets/reading_card.dart';

class ReadingLibraryScreen extends ConsumerStatefulWidget {
  const ReadingLibraryScreen({super.key});

  @override
  ConsumerState<ReadingLibraryScreen> createState() => _ReadingLibraryScreenState();
}

class _ReadingLibraryScreenState extends ConsumerState<ReadingLibraryScreen> {
  final _api = ReadingApiService();

  List<ReadingCategory> _categories = [];
  List<ReadingPassage> _passages = [];
  bool _loading = true;
  String _selectedCategoryId = 'cat_1';
  String _selectedCefr = 'All';

  final _cefrLevels = const ['All', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCefr != 'All') count++;
    if (_selectedCategoryId != 'cat_1') count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _load();
    Future.microtask(() {
      ref.read(xpStreakProvider.notifier).loadXpAndStreak();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await _api.getCategories();
      final passages = await _api.getPassages(
        categoryId: _selectedCategoryId,
        cefrLevel: _selectedCefr,
      );
      if (mounted) {
        setState(() {
          _categories = cats;
          _passages = passages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyFilters() async {
    setState(() => _loading = true);
    try {
      final passages = await _api.getPassages(
        categoryId: _selectedCategoryId,
        cefrLevel: _selectedCefr,
      );
      if (mounted) setState(() { _passages = passages; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    String tempCefr = _selectedCefr;
    String tempCategoryId = _selectedCategoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Bộ lọc bài đọc",
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempCefr = 'All';
                            tempCategoryId = 'cat_1';
                          });
                        },
                        child: const Text("Đặt lại"),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // CEFR section
                  Text("Trình độ CEFR", style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cefrLevels.map((level) {
                      final isSelected = tempCefr == level;
                      return ChoiceChip(
                        label: Text(level == 'All' ? 'Tất cả' : level),
                        selected: isSelected,
                        selectedColor: AppColors.brandPrimary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (v) {
                          if (v) setModalState(() => tempCefr = level);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Category section
                  if (_categories.isNotEmpty) ...[
                    Text("Danh mục", style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = tempCategoryId == cat.id;
                        return ChoiceChip(
                          label: Text(cat.title.isEmpty ? cat.slug : cat.title),
                          selected: isSelected,
                          selectedColor: AppColors.brandPrimary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.brandPrimary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.brandPrimary
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (v) {
                            if (v) setModalState(() => tempCategoryId = cat.id);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedCefr = tempCefr;
                          _selectedCategoryId = tempCategoryId;
                        });
                        _applyFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Áp dụng bộ lọc",
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpStreakState = ref.watch(xpStreakProvider);
    final streak = xpStreakState.streakInfo?.currentStreak ?? 0;
    final xp = xpStreakState.xpInfo?.totalXp ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Luyện đọc hiểu"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.streak.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 18),
              const SizedBox(width: 4),
              Text("$streak", style: AppTypography.labelMedium.copyWith(
                color: AppColors.streak, fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.xp.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.bolt_rounded, color: AppColors.xp, size: 18),
              const SizedBox(width: 4),
              Text("$xp XP", style: AppTypography.labelMedium.copyWith(
                color: AppColors.xp, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _load(),
            ref.read(xpStreakProvider.notifier).loadXpAndStreak(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Full-Width Filter Trigger Bar ─────────────────────────
              InkWell(
                onTap: () => _showFilterBottomSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _activeFilterCount > 0
                        ? AppColors.brandPrimary.withValues(alpha: 0.1)
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _activeFilterCount > 0
                          ? AppColors.brandPrimary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: _activeFilterCount > 0
                            ? AppColors.brandPrimary
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Bộ lọc bài đọc",
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _activeFilterCount > 0
                                ? AppColors.brandPrimary
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$_activeFilterCount bộ lọc",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                    ],
                  ),
                ),
              ),

              // ── Active Filters Summary Tags ───────────────────────────
              if (_activeFilterCount > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "Đang lọc:",
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_selectedCefr != 'All')
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InputChip(
                                  label: Text("CEFR: $_selectedCefr"),
                                  onDeleted: () {
                                    setState(() => _selectedCefr = 'All');
                                    _applyFilters();
                                  },
                                  deleteIconColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            if (_selectedCategoryId != 'cat_1') ...[
                              () {
                                final cat = _categories.firstWhere(
                                  (c) => c.id == _selectedCategoryId,
                                  orElse: () => const ReadingCategory(id: '', title: '', slug: ''),
                                );
                                final label = cat.title.isNotEmpty ? cat.title : cat.slug;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InputChip(
                                    label: Text("Danh mục: $label"),
                                    onDeleted: () {
                                      setState(() => _selectedCategoryId = 'cat_1');
                                      _applyFilters();
                                    },
                                    deleteIconColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              }(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // ── Section Title ─────────────────────────────────────────
              Text("Danh sách bài đọc",
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // ── Passages List ─────────────────────────────────────────
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_passages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("Không tìm thấy bài đọc nào",
                          style: AppTypography.titleMedium.copyWith(color: Colors.grey[600])),
                    ]),
                  ),
                )
              else
                Column(
                  children: _passages.map((passage) {
                    return Padding(
                      key: ValueKey('p_${passage.id}'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReadingCard(
                        passage: passage,
                        onTap: () => context.push('/reading/passages/${passage.id}'),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
