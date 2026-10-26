import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/environmental_item.dart';
import '../../utils/formatters.dart';
import '../common/status_badge.dart';
import '../ecoguide/ecoguide_strip.dart';

class RecordCard extends StatelessWidget {
  final EnvironmentalItem item;
  final VoidCallback onTap;
  final VoidCallback? onAsk;
  final String? distanceLabel;

  const RecordCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onAsk,
    this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = item.isOfficial
        ? AppTheme.officialBadge
        : AppTheme.communityBadge;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.shadowOf(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyBold.copyWith(
                            color: AppTheme.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(isOfficial: item.isOfficial),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.subtitle.copyWith(
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppTheme.textTertiaryOf(context),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          item.county,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textTertiaryOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Icon(
                        Icons.event_outlined,
                        size: 14,
                        color: AppTheme.textTertiaryOf(context),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formatDate(item.date),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textTertiaryOf(context),
                        ),
                      ),
                    ],
                  ),
                  if (onAsk != null || distanceLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (distanceLabel != null) ...[
                          Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: AppTheme.actionTeal,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            distanceLabel!,
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.actionTeal,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (onAsk != null) AskEcoGuidePill(onTap: onAsk!),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
