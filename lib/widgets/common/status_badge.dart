import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final bool isOfficial;

  const StatusBadge({super.key, required this.isOfficial});

  @override
  Widget build(BuildContext context) {
    final color = isOfficial ? AppTheme.officialBadge : AppTheme.communityBadge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        isOfficial ? 'OFFICIAL' : 'COMMUNITY REPORT',
        style: AppTheme.caption.copyWith(color: color),
      ),
    );
  }
}

class ApproximateLocationBadge extends StatelessWidget {
  const ApproximateLocationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_searching_rounded,
          size: 13,
          color: AppTheme.textTertiaryOf(context),
        ),
        const SizedBox(width: 4),
        Text(
          'Approximate location',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textTertiaryOf(context),
          ),
        ),
      ],
    );
  }
}
