import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Widget hiển thị số sao đạt được (0-3 sao).
///
/// Quy tắc tính sao (client-side):
/// - score >= 90 → 3 sao
/// - score >= 80 → 2 sao
/// - score >= passThreshold → 1 sao
/// - ngược lại → 0 sao
///
/// Sử dụng pattern tương tự StarRating trong Vocabulary feature.
class GrammarStarRating extends StatelessWidget {
  final int stars;
  final int maxStars;
  final double size;
  final bool animated;
  final Duration animationDelay;

  const GrammarStarRating({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.size = 20,
    this.animated = false,
    this.animationDelay = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final isFilled = index < stars;

        Widget star = Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFilled ? AppColors.xp : Colors.grey[400],
          size: size,
        );

        if (animated && isFilled) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: star,
          );
        }

        return Padding(
          padding: EdgeInsets.only(left: index > 0 ? 2 : 0),
          child: star,
        );
      }),
    );
  }
}

/// Widget hiển thị sao với animation tuần tự (dùng cho Result screen).
class GrammarStarRatingAnimated extends StatefulWidget {
  final int stars;
  final int maxStars;
  final double size;
  final Duration staggerDelay;

  const GrammarStarRatingAnimated({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.size = 48,
    this.staggerDelay = const Duration(milliseconds: 300),
  });

  @override
  State<GrammarStarRatingAnimated> createState() => _GrammarStarRatingAnimatedState();
}

class _GrammarStarRatingAnimatedState extends State<GrammarStarRatingAnimated> {
  int _visibleStars = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 1; i <= widget.stars; i++) {
      await Future.delayed(widget.staggerDelay);
      if (mounted) {
        setState(() {
          _visibleStars = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxStars, (index) {
        final isFilled = index < _visibleStars;
        final shouldAnimate = index < widget.stars && index < _visibleStars;

        Widget star = Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: isFilled ? AppColors.xp : Colors.grey[400],
          size: widget.size,
        );

        if (shouldAnimate) {
          return TweenAnimationBuilder<double>(
            key: ValueKey(index),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: star,
          );
        }

        return Padding(
          padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
          child: star,
        );
      }),
    );
  }
}
