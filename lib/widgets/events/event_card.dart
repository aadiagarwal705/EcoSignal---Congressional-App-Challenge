import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/community_event.dart';
import '../../utils/formatters.dart';

class EventCard extends StatelessWidget {
  final CommunityEvent event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(color: AppTheme.eventBadge.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.eventBadge, size: 22),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatEventWhen(event.dateTime),
                    style: AppTheme.subtitle.copyWith(color: AppTheme.eventBadge),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: AppTheme.textTertiaryOf(context)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${event.locationLabel} · ${event.county}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption.copyWith(color: AppTheme.textTertiaryOf(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'By ${event.organizerName}',
                        style: AppTheme.caption.copyWith(color: AppTheme.textSecondaryOf(context)),
                      ),
                      const Spacer(),
                      Icon(Icons.groups_rounded, size: 14, color: AppTheme.textTertiaryOf(context)),
                      const SizedBox(width: 2),
                      Text('${event.attendeeCount}', style: AppTheme.caption.copyWith(color: AppTheme.textTertiaryOf(context))),
                    ],
                  ),
                  if (event.reportId != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.communityBadge.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        'For a reported issue',
                        style: AppTheme.caption.copyWith(color: AppTheme.communityBadge),
                      ),
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
