import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_theme.dart';
import '../models/community_report.dart';
import '../services/reports.dart';
import '../services/user_profile.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/common/bookmark_button.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/media/media_viewer.dart';
import 'ecoguide_chat.dart';

class ReportDetailScreen extends StatefulWidget {
  final CommunityReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _deleting = false;

  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == widget.report.submittedBy;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ReportService().deleteReport(widget.report.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not delete the report: $e',
          type: SnackType.error,
        );
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Detail'),
        actions: [
          SaveToggleButton(
            isSavedStream: UserProfileService().isReportSavedStream(report.id),
            onToggle: (save) =>
                UserProfileService().setReportSaved(report.id, save),
          ),
          if (_isOwner)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              onPressed: _deleting ? null : _confirmDelete,
              tooltip: 'Delete report',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        children: [
          if (report.mediaUrls.isNotEmpty) ...[
            _MediaCarousel(urls: report.mediaUrls),
            const SizedBox(height: AppTheme.spaceLarge),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.communityBadge.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  report.icon,
                  color: AppTheme.communityBadge,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusBadge(isOfficial: false),
                    const SizedBox(height: 6),
                    Text(
                      report.title,
                      style: AppTheme.h2.copyWith(
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EcoGuideScreen(item: report)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Ask EcoGuide AI about this'),
              style: AppTheme.primaryButtonOf(context).copyWith(
                backgroundColor: const WidgetStatePropertyAll(AppTheme.ai),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: AppTheme.spaceLarge,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.shadowOf(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESCRIPTION',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textTertiaryOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.description,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.shadowOf(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCATION',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textTertiaryOf(context),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Text(
                        report.locationLabel,
                        style: AppTheme.body.copyWith(
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      report.county,
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      formatDate(report.date),
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                if (report.locationApproximate) ...[
                  const SizedBox(height: AppTheme.spaceSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.location_searching_rounded,
                        size: 14,
                        color: AppTheme.textTertiaryOf(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Approximate location — based on county, not device GPS.',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textTertiaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.shadowOf(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT CAN I DO?',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textTertiaryOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 18,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Text(
                        'Typically handled by ${report.category.responsibleAgency}.',
                        style: AppTheme.body.copyWith(
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLightOf(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.textSecondaryOf(context),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'This is a community report, not an official Maryland record.',
                    style: AppTheme.subtitle.copyWith(
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaCarousel extends StatefulWidget {
  final List<String> urls;
  const _MediaCarousel({required this.urls});

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: SizedBox(
            height: 220,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                for (int i = 0; i < widget.urls.length; i++)
                  GestureDetector(
                    onTap: () => openMediaViewer(
                      context,
                      urls: widget.urls,
                      initialIndex: i,
                    ),
                    child: isVideoUrl(widget.urls[i])
                        ? _VideoThumb(url: widget.urls[i])
                        : Image.network(
                            widget.urls[i],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            errorBuilder: (context, error, stack) => Container(
                              color: AppTheme.surfaceLightOf(context),
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppTheme.textTertiaryOf(context),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.urls.length > 1) ...[
          const SizedBox(height: AppTheme.spaceSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.urls.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? AppTheme.primaryOf(context)
                        : AppTheme.textTertiaryOf(
                            context,
                          ).withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// a paused first-frame preview, tapping it opens the full-screen player instead
class _VideoThumb extends StatefulWidget {
  final String url;
  const _VideoThumb({required this.url});

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
        const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 56),
      ],
    );
  }
}
