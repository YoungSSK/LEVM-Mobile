import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/profile/models/user_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular avatar with URL fallback to two-letter initials on a gradient
/// background. Always wrapped in a white "ring" + subtle shadow so it stays
/// visible against any brand-tinted background (e.g. the profile SliverAppBar).
class LEVMAvatar extends StatelessWidget {
  final UserModel user;
  final double size;

  const LEVMAvatar({
    super.key,
    required this.user,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final inner = user.hasAvatar
        ? _AvatarImage(url: user.avatar!, radius: radius)
        : _initials(context, radius);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(child: inner),
    );
  }

  Widget _initials(BuildContext context, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: AppTypography.headlineLarge.copyWith(
          color: Colors.white,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String url;
  final double radius;
  const _AvatarImage({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      placeholder: (_, _) => _Placeholder(radius: radius),
      errorWidget: (_, _, _) => _Placeholder(radius: radius),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double radius;
  const _Placeholder({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
