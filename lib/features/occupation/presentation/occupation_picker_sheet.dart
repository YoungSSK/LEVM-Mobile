import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/occupation_models.dart';
import '../providers/occupation_providers.dart';

/// Bottom-sheet đơn giản: chỉ cho user chọn **nhóm ngành** (category).
/// Không hiển thị occupation cụ thể bên trong — chỉ cần chọn IT chứ không
/// cần chọn ngành con trong IT.
class OccupationPickerSheet extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const OccupationPickerSheet({super.key, this.initialCategoryId});

  @override
  ConsumerState<OccupationPickerSheet> createState() =>
      _OccupationPickerSheetState();
}

class _OccupationPickerSheetState
    extends ConsumerState<OccupationPickerSheet> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(occupationCategoriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn nhóm ngành',
                    style: AppTypography.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Tải lại',
                  onPressed: () => ref
                      .read(occupationCategoriesProvider.notifier)
                      .refresh(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bạn có thể chọn lại nhóm ngành bất kỳ lúc nào.',
              style: AppTypography.bodySmall.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: categoriesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref
                      .read(occupationCategoriesProvider.notifier)
                      .refresh(),
                ),
                data: (state) {
                  if (state.loading && state.categories.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.categories.isEmpty) {
                    return _EmptyState(
                      onRetry: () => ref
                          .read(occupationCategoriesProvider.notifier)
                          .refresh(),
                    );
                  }
                  return _CategoryList(
                    categories: state.categories,
                    selectedId: _selectedCategoryId,
                    onSelected: (cat) => setState(() {
                      _selectedCategoryId = cat.id;
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedCategoryId == null
                    ? null
                    : () {
                        final categories = ref
                                .read(occupationCategoriesProvider)
                                .value
                                ?.categories ??
                            const <OccupationCategoryModel>[];
                        final picked = categories.firstWhere(
                          (c) => c.id == _selectedCategoryId,
                          orElse: () => const OccupationCategoryModel(
                            id: '',
                            name: '',
                          ),
                        );
                        if (picked.id.isEmpty) return;
                        Navigator.of(context).pop(picked);
                      },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Xác nhận'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<OccupationCategoryModel> categories;
  final String? selectedId;
  final ValueChanged<OccupationCategoryModel> onSelected;

  const _CategoryList({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == selectedId;
          return ListTile(
            dense: true,
            selected: isSelected,
            selectedTileColor:
                AppColors.brandPrimary.withValues(alpha: 0.08),
            title: Text(
              cat.name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.brandPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: cat.description.isNotEmpty
                ? Text(
                    cat.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  )
                : null,
            trailing: isSelected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.brandPrimary,
                  )
                : null,
            onTap: () => onSelected(cat),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.work_off_outlined,
            size: 48,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có nhóm ngành nào để hiển thị.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
