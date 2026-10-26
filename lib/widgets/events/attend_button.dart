import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class AttendButton extends StatelessWidget {
  final int count;
  final bool attending;
  final bool busy;
  final VoidCallback onTap;

  const AttendButton({
    super.key,
    required this.count,
    required this.attending,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 person attending' : '$count people attending';
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onTap,
          icon: busy
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(attending ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 18),
          label: Text(attending ? "I'm going" : 'Attend'),
          style: OutlinedButton.styleFrom(
            foregroundColor: attending ? Colors.white : AppTheme.eventBadge,
            backgroundColor: attending ? AppTheme.eventBadge : null,
            side: BorderSide(color: AppTheme.eventBadge),
          ),
        ),
      ],
    );
  }
}
