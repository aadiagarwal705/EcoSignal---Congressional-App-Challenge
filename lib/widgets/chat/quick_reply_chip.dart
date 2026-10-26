import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const QuickReplyChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.ai.withValues(alpha: 0.10),
      side: BorderSide.none,
      labelStyle: AppTheme.bodyBold.copyWith(color: AppTheme.ai, fontSize: 13),
    );
  }
}
