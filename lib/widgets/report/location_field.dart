import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class LocationField extends StatelessWidget {
  final String? label;
  final VoidCallback onTap;

  const LocationField({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chosen = label != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: chosen
              ? AppTheme.communityBadge.withValues(alpha: 0.08)
              : null,
          border: chosen
              ? null
              : Border.all(
                  color: AppTheme.textTertiaryOf(
                    context,
                  ).withValues(alpha: 0.4),
                  width: 1.5,
                ),
        ),
        child: Row(
          children: [
            Icon(
              chosen ? Icons.place_rounded : Icons.add_location_alt_outlined,
              color: chosen
                  ? AppTheme.communityBadge
                  : AppTheme.textSecondaryOf(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: chosen
                  ? Text(
                      label!,
                      style: AppTheme.bodyBold.copyWith(
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    )
                  : Text(
                      'Choose Location on Map',
                      style: AppTheme.bodyBold.copyWith(
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
            ),
            Text(
              chosen ? 'Change' : 'Select',
              style: AppTheme.bodyBold.copyWith(
                color: AppTheme.primaryOf(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
