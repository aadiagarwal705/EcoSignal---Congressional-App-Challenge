import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const HeaderButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: active ? AppTheme.brandGreen : AppTheme.textSecondaryOf(context),
      ),
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: active ? 0.9 : 0.5),
      ),
    );
  }
}
