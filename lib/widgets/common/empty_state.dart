import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // a plain Center can't shrink below its content - if a tall header above
    // this leaves too little room, that used to overflow instead of scrolling.
    // this also gets placed straight inside a bare ListView in a few places,
    // which hands down an unbounded height - minHeight has to stay 0 there,
    // not infinity, or the whole thing silently fails to paint
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0),
          child: Center(child: _content(context)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceXLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryOf(context).withValues(alpha: 0.10),
                  AppTheme.secondaryOf(context).withValues(alpha: 0.10),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 72,
              color: AppTheme.primaryOf(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            title,
            style: AppTheme.h2.copyWith(color: AppTheme.textPrimaryOf(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLarge,
            ),
            child: Text(
              message,
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppTheme.spaceXLarge),
            ElevatedButton(
              onPressed: onAction,
              style: AppTheme.primaryButtonOf(context),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
