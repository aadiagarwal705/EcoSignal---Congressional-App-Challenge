import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class ChatWelcome extends StatelessWidget {
  final bool hasItem;
  final List<String> suggestions;
  final ValueChanged<String> onPick;

  const ChatWelcome({
    super.key,
    required this.hasItem,
    required this.suggestions,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      children: [
        const SizedBox(height: AppTheme.spaceMedium),
        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: AppTheme.aiGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.ai.withValues(alpha: 0.40),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        Text(
          hasItem ? 'Ask about this' : 'Ask EcoGuide anything',
          textAlign: TextAlign.center,
          style: AppTheme.h2.copyWith(color: AppTheme.textPrimaryOf(context)),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          hasItem
              ? "EcoGuide already knows what you're looking at. Pick a question or type your own."
              : "Questions about Maryland's land, water and air, how to report a problem, or what a record means — not just one report.",
          textAlign: TextAlign.center,
          style: AppTheme.body.copyWith(
            color: AppTheme.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
            child: InkWell(
              onTap: () => onPick(suggestion),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMedium,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.ai.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.ai.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppTheme.ai,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: AppTheme.bodyBold.copyWith(
                          color: AppTheme.textPrimaryOf(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.north_east_rounded,
                      size: 16,
                      color: AppTheme.ai,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
