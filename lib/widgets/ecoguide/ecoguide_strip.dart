import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class EcoGuideStrip extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const EcoGuideStrip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8E5CE6), Color(0xFF6A3FCB)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium + 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ai.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.ai,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyBold.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.subtitle.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class AskEcoGuidePill extends StatelessWidget {
  final VoidCallback onTap;

  const AskEcoGuidePill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.ai.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 13,
              color: AppTheme.ai,
            ),
            const SizedBox(width: 4),
            Text(
              'Ask EcoGuide',
              style: AppTheme.caption.copyWith(
                color: AppTheme.ai,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
