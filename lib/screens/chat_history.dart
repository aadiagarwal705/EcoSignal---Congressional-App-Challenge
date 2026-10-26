import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../main.dart' show mainScreenTabRequestNotifier;
import '../models/chat_thread.dart';
import '../services/chat_store.dart';
import '../services/records.dart';
import '../services/reports.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/shimmer.dart';
import 'ecoguide_chat.dart';

class EcoGuideHistoryScreen extends StatefulWidget {
  const EcoGuideHistoryScreen({super.key});

  @override
  State<EcoGuideHistoryScreen> createState() => _EcoGuideHistoryScreenState();
}

class _EcoGuideHistoryScreenState extends State<EcoGuideHistoryScreen> {
  String? _openingThreadId;

  Future<void> _open(EcoGuideChatThread thread) async {
    if (thread.isGeneral) {
      Navigator.popUntil(context, (route) => route.isFirst);
      mainScreenTabRequestNotifier.value = 5;
      return;
    }

    final threadId = EcoGuideChatService().threadId(
      thread.itemType,
      thread.itemId,
    );
    setState(() => _openingThreadId = threadId);
    try {
      final item = thread.isRecord
          ? await RecordService().getRecord(thread.itemId)
          : await ReportService().getReport(thread.itemId);
      if (!mounted) return;
      if (item == null) {
        showAppSnackBar(
          context,
          'That ${thread.isRecord ? 'record' : 'report'} is no longer available.',
          type: SnackType.error,
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EcoGuideScreen(item: item)),
      );
    } finally {
      if (mounted) setState(() => _openingThreadId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My EcoGuide Chats')),
      body: StreamBuilder<List<EcoGuideChatThread>>(
        stream: EcoGuideChatService().myThreadsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const ShimmerList();
          final threads = snapshot.data!;
          if (threads.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No chats yet',
              message:
                  "Ask EcoGuide anything and it'll show up here to revisit later.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            itemCount: threads.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTheme.spaceMedium),
            itemBuilder: (context, index) {
              final thread = threads[index];
              final threadId = EcoGuideChatService().threadId(
                thread.itemType,
                thread.itemId,
              );
              final busy = _openingThreadId == threadId;
              return InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                onTap: busy ? null : () => _open(thread),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceOf(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.shadowOf(context),
                  ),
                  child: Row(
                    children: [
                      thread.lastImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.network(
                                thread.lastImageUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOf(
                                  context,
                                ).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                thread.isGeneral
                                    ? Icons.auto_awesome_rounded
                                    : (thread.isRecord
                                          ? Icons.description_rounded
                                          : Icons.assignment_outlined),
                                color: AppTheme.primaryOf(context),
                                size: 20,
                              ),
                            ),
                      const SizedBox(width: AppTheme.spaceMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thread.itemTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyBold.copyWith(
                                color: AppTheme.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              thread.lastMessagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.subtitle.copyWith(
                                color: AppTheme.textSecondaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDate(thread.updatedAt),
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textTertiaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (busy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textTertiaryOf(context),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
