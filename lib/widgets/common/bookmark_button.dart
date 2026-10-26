import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class SaveToggleButton extends StatelessWidget {
  final Stream<bool> isSavedStream;
  final ValueChanged<bool> onToggle;

  const SaveToggleButton({
    super.key,
    required this.isSavedStream,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: isSavedStream,
      builder: (context, snapshot) {
        final saved = snapshot.data ?? false;
        return IconButton(
          icon: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          ),
          color: saved ? AppTheme.primaryOf(context) : null,
          tooltip: saved ? 'Remove from Saved' : 'Save',
          onPressed: () => onToggle(!saved),
        );
      },
    );
  }
}
