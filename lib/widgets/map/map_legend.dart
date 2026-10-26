import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowOf(context),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppTheme.spaceMedium,
        runSpacing: 4,
        children: [
          _entry(context, AppTheme.officialBadge, 'Official'),
          _entry(context, AppTheme.communityBadge, 'Community'),
          _entry(context, AppTheme.myReportBadge, 'Mine'),
          _entry(context, AppTheme.eventBadge, 'Events'),
        ],
      ),
    );
  }

  Widget _entry(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
