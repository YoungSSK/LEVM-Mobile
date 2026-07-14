import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/occupation_api.dart';
import '../models/occupation_models.dart';

final occupationApiProvider =
    Provider<OccupationApi>((ref) => OccupationApi());

/// Chỉ chứa nhóm ngành (OccupationCategory) — picker hiện tại chỉ cần user
/// chọn category, không cần chọn occupation cụ thể bên trong.
class OccupationCategoriesState {
  final List<OccupationCategoryModel> categories;
  final bool loading;

  const OccupationCategoriesState({
    this.categories = const [],
    this.loading = false,
  });

  OccupationCategoriesState copyWith({
    List<OccupationCategoryModel>? categories,
    bool? loading,
  }) {
    return OccupationCategoriesState(
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
    );
  }
}

class OccupationCategoriesNotifier
    extends AsyncNotifier<OccupationCategoriesState> {
  @override
  Future<OccupationCategoriesState> build() async {
    return const OccupationCategoriesState();
  }

  Future<void> ensureLoaded() async {
    final current = state.value ?? const OccupationCategoriesState();
    if (current.categories.isNotEmpty || current.loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    state = AsyncData(
      (state.value ?? const OccupationCategoriesState())
          .copyWith(loading: true),
    );
    try {
      final api = ref.read(occupationApiProvider);
      final categories = await api.getCategories();
      state = AsyncData(
        OccupationCategoriesState(
          categories:
              categories.where((c) => c.isActive).toList(growable: false),
          loading: false,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final occupationCategoriesProvider =
    AsyncNotifierProvider<OccupationCategoriesNotifier,
        OccupationCategoriesState>(
  OccupationCategoriesNotifier.new,
);
