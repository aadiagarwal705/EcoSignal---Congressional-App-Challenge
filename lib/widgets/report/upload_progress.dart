import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class UploadProgressBar extends StatelessWidget {
  final int sent;
  final int total;
  final int done;
  final int count;
  final bool saving;
  final bool reconnecting;
  final VoidCallback onCancel;

  const UploadProgressBar({
    super.key,
    required this.sent,
    required this.total,
    required this.done,
    required this.count,
    required this.saving,
    required this.reconnecting,
    required this.onCancel,
  });

  String _mb(int bytes) => (bytes / 1048576).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final double? fraction = total == 0
        ? null
        : (sent / total).clamp(0.0, 1.0).toDouble();
    final percent = fraction == null ? 0 : (fraction * 100).round();
    final label = saving
        ? 'Saving your report…'
        : reconnecting
        ? 'Reconnecting… your upload will resume on its own'
        : 'Uploading $done of $count files · $percent% (${_mb(sent)} / ${_mb(total)} MB)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (reconnecting && !saving) ...[
              Icon(Icons.wifi_off_rounded, size: 14, color: AppTheme.error),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: reconnecting && !saving
                      ? AppTheme.error
                      : AppTheme.textSecondaryOf(context),
                ),
              ),
            ),
            if (!saving)
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Cancel'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: saving ? null : fraction,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
