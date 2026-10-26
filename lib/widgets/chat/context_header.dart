import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/environmental_item.dart';

class ContextHeader extends StatelessWidget {
  final EnvironmentalItem item;
  final VoidCallback onTap;

  const ContextHeader({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        color: AppTheme.ai.withValues(alpha: 0.10),
        child: Row(
          children: [
            Icon(item.icon, color: AppTheme.ai),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discussing',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textTertiaryOf(context),
                    ),
                  ),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyBold.copyWith(
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textTertiaryOf(context),
            ),
          ],
        ),
      ),
    );
  }
}
