import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class AskEcoGuideSheet extends StatelessWidget {
  const AskEcoGuideSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.ai.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Report sent — thank you!',
              style: AppTheme.h2.copyWith(
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Want to know what you can do right now at the spot? Ask EcoGuide AI for immediate, practical guidance about this location and issue.',
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Ask EcoGuide AI'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.ai,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No thanks, view my report'),
            ),
          ],
        ),
      ),
    );
  }
}
