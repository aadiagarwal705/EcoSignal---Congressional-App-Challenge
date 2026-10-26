import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

enum SnackType { info, success, error }

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final icon = switch (type) {
    SnackType.success => Icons.check_circle_rounded,
    SnackType.error => Icons.error_rounded,
    SnackType.info => Icons.info_rounded,
  };
  final color = switch (type) {
    SnackType.success => AppTheme.success,
    SnackType.error => AppTheme.error,
    SnackType.info => AppTheme.textPrimaryOf(context),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodyBold.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      duration: duration,
    ),
  );
}
