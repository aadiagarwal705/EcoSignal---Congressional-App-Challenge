import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final EcoGuideMessage message;
  final VoidCallback? onReport;
  final bool reporting;

  const ChatBubble({
    super.key,
    required this.message,
    this.onReport,
    this.reporting = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == EcoGuideRole.user;
    final hasImage = message.localImage != null || message.imageUrl != null;
    final bubbleColor = isUser
        ? AppTheme.ai
        : (message.isError
              ? AppTheme.error.withValues(alpha: 0.12)
              : AppTheme.surfaceOf(context));
    final textColor = isUser
        ? Colors.white
        : (message.isError ? AppTheme.error : AppTheme.textPrimaryOf(context));

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: AppTheme.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppTheme.radiusMedium),
          topRight: const Radius.circular(AppTheme.radiusMedium),
          bottomLeft: Radius.circular(isUser ? AppTheme.radiusMedium : 4),
          bottomRight: Radius.circular(isUser ? 4 : AppTheme.radiusMedium),
        ),
        boxShadow: isUser ? null : AppTheme.shadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: message.localImage != null
                  ? Image.file(
                      message.localImage!,
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      message.imageUrl!,
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
            ),
          if (hasImage && message.text.isNotEmpty)
            const SizedBox(height: AppTheme.spaceSmall),
          if (message.text.isNotEmpty)
            Text(message.text, style: AppTheme.body.copyWith(color: textColor)),
        ],
      ),
    );

    final reportButton = isUser && hasImage && onReport != null
        ? Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: reporting ? null : onReport,
                icon: reporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag_outlined, size: 16),
                label: Text(reporting ? 'Opening report...' : 'Report this'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.ai,
                  side: const BorderSide(color: AppTheme.ai),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          )
        : null;

    if (isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(alignment: Alignment.centerRight, child: bubble),
          ?reportButton,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _BotAvatar(),
        const SizedBox(width: 8),
        Flexible(child: bubble),
      ],
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppTheme.ai.withValues(alpha: 0.15),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 15,
        color: AppTheme.ai,
      ),
    );
  }
}

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BotAvatar(),
        const SizedBox(width: AppTheme.spaceSmall),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceMedium,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceOf(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusMedium),
              topRight: Radius.circular(AppTheme.radiusMedium),
              bottomRight: Radius.circular(AppTheme.radiusMedium),
            ),
            boxShadow: AppTheme.shadowOf(context),
          ),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.textTertiaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
