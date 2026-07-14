import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Simple brand logo block (text + a little icon badge). No asset needed.
class LEVMLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const LEVMLogo({super.key, this.size = 64, this.showWordmark = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.3),
            gradient: const LinearGradient(
              colors: AppColors.brandGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            "L",
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 10),
          Text(
            "LEVM",
            style: AppTypography.displayMedium.copyWith(
              fontSize: 24,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}
