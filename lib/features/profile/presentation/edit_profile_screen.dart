import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_feedback.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/levm_avatar.dart';
import '../../../core/widgets/levm_buttons.dart';
import '../../../core/widgets/levm_text_field.dart';
import '../../occupation/models/occupation_models.dart';
import '../../occupation/presentation/occupation_picker_sheet.dart';
import '../../occupation/providers/occupation_providers.dart';
import '../models/profile_requests.dart';
import '../models/user_model.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _occupationCategoryId;
  String? _occupationCategoryName;

  bool _initialized = false;
  bool _submitting = false;
  bool _uploadingAvatar = false;
  String? _serverError;

  // Snapshot ban đầu để chỉ gửi các field đã thay đổi.
  String? _originalDisplayName;
  String? _originalBio;
  String? _originalOccupationCategoryId;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _hydrateFrom(UserModel user) {
    if (_initialized) return;
    _initialized = true;
    _displayNameCtrl.text = user.displayName;
    _bioCtrl.text = user.bio ?? '';
    _occupationCategoryId = user.occupationCategoryId;
    _occupationCategoryName = user.occupationCategoryName;
    _originalDisplayName = user.displayName;
    _originalBio = user.bio;
    _originalOccupationCategoryId = user.occupationCategoryId;
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      // Truyền `XFile` thay vì `path` để hoạt động đúng trên cả native
      // lẫn Flutter web (web trả về `blob:` URL).
      await ref
          .read(currentUserProvider.notifier)
          .uploadAvatar(picked);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Cập nhật ảnh đại diện thành công!');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        _friendly(e, fallback: 'Upload ảnh thất bại, bạn thử lại nhé.'),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _openOccupationPicker() async {
    // Đảm bảo danh sách nhóm ngành đã được load.
    await ref
        .read(occupationCategoriesProvider.notifier)
        .ensureLoaded();

    if (!mounted) return;
    final category = await showModalBottomSheet<OccupationCategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const OccupationPickerSheet(),
    );

    if (category != null && mounted) {
      setState(() {
        _occupationCategoryId = category.id;
        _occupationCategoryName = category.name;
      });
    }
  }

  void _clearOccupation() {
    setState(() {
      _occupationCategoryId = null;
      _occupationCategoryName = null;
    });
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = UpdateProfileRequest(
      displayName: _displayNameCtrl.text.trim() != _originalDisplayName
          ? _displayNameCtrl.text.trim()
          : null,
      bio: _bioCtrl.text.trim() != (_originalBio ?? '')
          ? _bioCtrl.text.trim()
          : null,
      occupationCategoryId: _occupationCategoryId != _originalOccupationCategoryId
          ? _occupationCategoryId
          : null,
    );

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa thay đổi thông tin nào.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(currentUserProvider.notifier).updateProfile(payload);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Đã cập nhật hồ sơ của bạn!');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverError = _friendly(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendly(Object error, {String fallback = ''}) {
    final raw = error.toString();
    if (raw.contains('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return fallback.isNotEmpty
        ? fallback
        : 'Cập nhật chưa thành công, bạn thử lại sau nhé.';
  }

  Widget _buildAvatarPreview(UserModel user) {
    // Cho preview optimistic — text hiện tại nhưng avatar lấy từ server.
    final preview = user.copyWith(displayName: _displayNameCtrl.text);
    return Center(
      child: LEVMAvatar(user: preview, size: 96),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final remainingBio =
        Validators.bioMaxLength - _bioCtrl.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _onSubmit,
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Không có dữ liệu hồ sơ'));
          }
          _hydrateFrom(user);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAvatarPreview(user),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _uploadingAvatar ? null : _pickAndUploadAvatar,
                      icon: _uploadingAvatar
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _uploadingAvatar
                            ? 'Đang tải ảnh lên…'
                            : (user.hasAvatar
                                ? 'Đổi ảnh đại diện'
                                : 'Chọn ảnh từ thư viện'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LEVMTextField(
                    controller: _displayNameCtrl,
                    label: 'Tên hiển thị',
                    hint: 'Tên bạn muốn mọi người gọi',
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    validator: Validators.displayName,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _OccupationCard(
                    occupationCategoryId: _occupationCategoryId,
                    occupationCategoryName: _occupationCategoryName,
                    onPick: _openOccupationPicker,
                    onClear: _clearOccupation,
                  ),
                  const SizedBox(height: 16),
                  LEVMTextField(
                    controller: _bioCtrl,
                    label: 'Giới thiệu',
                    hint: 'Kể về bạn trong vài dòng…',
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    maxLength: Validators.bioMaxLength,
                    counterText: 'Còn $remainingBio ký tự',
                    validator: Validators.bio,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_serverError != null) ...[
                    const SizedBox(height: 16),
                    InfoBanner(message: _serverError!),
                  ],
                  const SizedBox(height: 24),
                  LEVMPrimaryButton(
                    label: 'Lưu thay đổi',
                    leadingIcon: Icons.save_rounded,
                    isLoading: _submitting,
                    onPressed: _onSubmit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OccupationCard extends StatelessWidget {
  final String? occupationCategoryId;
  final String? occupationCategoryName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _OccupationCard({
    required this.occupationCategoryId,
    required this.occupationCategoryName,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChoice = occupationCategoryId != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandTertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: AppColors.brandTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhóm ngành đang học',
                  style: AppTypography.labelLarge.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasChoice
                      ? (occupationCategoryName ?? 'Đã chọn một nhóm ngành')
                      : 'Chưa chọn nhóm ngành',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
          if (hasChoice)
            IconButton(
              tooltip: 'Bỏ chọn',
              icon: const Icon(Icons.close_rounded),
              onPressed: onClear,
            ),
          TextButton(
            onPressed: onPick,
            child: Text(hasChoice ? 'Đổi' : 'Chọn'),
          ),
        ],
      ),
    );
  }
}