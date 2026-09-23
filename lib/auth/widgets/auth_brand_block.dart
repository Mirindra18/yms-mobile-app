import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class AuthBrandBlock extends StatelessWidget {
  const AuthBrandBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brown800,
            AppColors.brown950,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppColors.brown950,
              size: 38,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'YMS',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
              letterSpacing: 1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Formation & Excellence',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}