import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/community_event.dart';
import '../models/community_report.dart';
import '../services/admin_tools.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/shimmer.dart';
import '../widgets/common/status_badge.dart';
import 'event_detail.dart';
import 'report_detail.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(tabs: [Tab(text: 'Reports'), Tab(text: 'Events')]),
        ),
        body: const TabBarView(children: [_AdminReportsTab(), _AdminEventsTab()]),
      ),
    );
  }
}

class _AdminReportsTab extends StatefulWidget {
  const _AdminReportsTab();

  @override
  State<_AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<_AdminReportsTab> {
  final _service = AdminService();
  late Future<List<CommunityReport>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllReports();
  }

  Future<void> _refresh() async {
    final future = _service.getAllReports();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<CommunityReport>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ShimmerList();
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return ListView(
              children: const [
                EmptyState(
                  icon: Icons.shield_outlined,
                  title: 'No reports yet',
                  message:
                      'Community reports will show up here for review as they come in.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            itemCount: reports.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTheme.spaceMedium),
            itemBuilder: (context, index) => _AdminReportRow(
              key: ValueKey(reports[index].id),
              report: reports[index],
              service: _service,
              onChanged: _refresh,
            ),
          );
        },
      ),
    );
  }
}

class _AdminEventsTab extends StatefulWidget {
  const _AdminEventsTab();

  @override
  State<_AdminEventsTab> createState() => _AdminEventsTabState();
}

class _AdminEventsTabState extends State<_AdminEventsTab> {
  final _service = AdminService();
  late Future<List<CommunityEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllEvents();
  }

  Future<void> _refresh() async {
    final future = _service.getAllEvents();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<CommunityEvent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ShimmerList();
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return ListView(
              children: const [
                EmptyState(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'No events yet',
                  message: 'Organized cleanups and help events will show up here for review.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceMedium),
            itemBuilder: (context, index) => _AdminEventRow(
              key: ValueKey(events[index].id),
              event: events[index],
              service: _service,
              onChanged: _refresh,
            ),
          );
        },
      ),
    );
  }
}

class _AdminEventRow extends StatefulWidget {
  final CommunityEvent event;
  final AdminService service;
  final VoidCallback onChanged;

  const _AdminEventRow({super.key, required this.event, required this.service, required this.onChanged});

  @override
  State<_AdminEventRow> createState() => _AdminEventRowState();
}

class _AdminEventRowState extends State<_AdminEventRow> {
  bool? _organizerBanned;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.service.isUserBanned(widget.event.organizerUid).then((banned) {
      if (mounted) setState(() => _organizerBanned = banned);
    });
  }

  Future<void> _toggleBan() async {
    final willBan = !(_organizerBanned ?? false);
    if (willBan) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ban this organizer?'),
          content: const Text("They'll no longer be able to submit new community reports."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ban', style: TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _busy = true);
    try {
      await widget.service.setUserBanned(widget.event.organizerUid, willBan);
      if (mounted) setState(() => _organizerBanned = willBan);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Could not update the organizer: $e', type: SnackType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive() async {
    setState(() => _busy = true);
    final active = widget.event.status == EventStatus.active;
    try {
      await widget.service.setEventStatus(widget.event.id, active ? EventStatus.removed : EventStatus.active);
      widget.onChanged();
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Could not update the event: $e', type: SnackType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeletePermanently() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text("This removes the event entirely. This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await widget.service.deleteEventPermanently(widget.event.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not delete the event: $e', type: SnackType.error);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isActive = event.status == EventStatus.active;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppTheme.eventBadge.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.eventBadge, size: 20),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(event.title, style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
                          ),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: Text('REMOVED', style: AppTheme.caption.copyWith(color: AppTheme.error)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.county} · ${formatEventWhen(event.dateTime)}',
                        style: AppTheme.caption.copyWith(color: AppTheme.textTertiaryOf(context)),
                      ),
                      Text(
                        'Organized by ${event.organizerName} · ${event.attendeeCount} attending',
                        style: AppTheme.caption.copyWith(color: AppTheme.textTertiaryOf(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            Wrap(
              spacing: AppTheme.spaceSmall,
              runSpacing: AppTheme.spaceSmall,
              children: [
                OutlinedButton.icon(
                  onPressed: _toggleActive,
                  icon: Icon(isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16),
                  label: Text(isActive ? 'Remove' : 'Restore'),
                ),
                OutlinedButton.icon(
                  onPressed: _toggleBan,
                  icon: Icon((_organizerBanned ?? false) ? Icons.person_add_alt_outlined : Icons.block_outlined, size: 16),
                  label: Text((_organizerBanned ?? false) ? 'Unban organizer' : 'Ban organizer'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                ),
                IconButton(
                  onPressed: _confirmDeletePermanently,
                  icon: const Icon(Icons.delete_forever_outlined, size: 20),
                  tooltip: 'Delete permanently',
                  color: AppTheme.textTertiaryOf(context),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AdminReportRow extends StatefulWidget {
  final CommunityReport report;
  final AdminService service;
  final VoidCallback onChanged;

  const _AdminReportRow({
    super.key,
    required this.report,
    required this.service,
    required this.onChanged,
  });

  @override
  State<_AdminReportRow> createState() => _AdminReportRowState();
}

class _AdminReportRowState extends State<_AdminReportRow> {
  String? _reporterLabel;
  bool? _reporterBanned;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadReporter();
  }

  Future<void> _loadReporter() async {
    final results = await Future.wait([
      widget.service.getUserLabel(widget.report.submittedBy),
      widget.service.isUserBanned(widget.report.submittedBy),
    ]);
    if (mounted) {
      setState(() {
        _reporterLabel = results[0] as String?;
        _reporterBanned = results[1] as bool;
      });
    }
  }

  Future<void> _toggleActive() async {
    setState(() => _busy = true);
    final active = widget.report.status == ReportStatus.active;
    try {
      await widget.service.setReportStatus(
        widget.report.id,
        active ? ReportStatus.removed : ReportStatus.active,
      );
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not update the report: $e',
          type: SnackType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeletePermanently() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text(
          "This removes the report entirely, not just from public view. This can't be undone.",
        ),
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

    setState(() => _busy = true);
    try {
      await widget.service.deleteReportPermanently(widget.report.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not delete the report: $e',
          type: SnackType.error,
        );
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleBan() async {
    final willBan = !(_reporterBanned ?? false);
    if (willBan) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ban this reporter?'),
          content: const Text(
            "They'll no longer be able to submit new community reports.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ban', style: TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _busy = true);
    try {
      await widget.service.setUserBanned(widget.report.submittedBy, willBan);
      if (mounted) setState(() => _reporterBanned = willBan);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not update the reporter: $e',
          type: SnackType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isActive = report.status == ReportStatus.active;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(report: report),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.communityBadge.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    report.icon,
                    color: AppTheme.communityBadge,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report.title,
                              style: AppTheme.bodyBold.copyWith(
                                color: AppTheme.textPrimaryOf(context),
                              ),
                            ),
                          ),
                          isActive
                              ? const StatusBadge(isOfficial: false)
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spaceSmall,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    'REMOVED',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.categoryLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.subtitle.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${report.county} · ${formatDate(report.date)}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textTertiaryOf(context),
                        ),
                      ),
                      Text(
                        _reporterLabel == null
                            ? 'Reported by ${report.submittedBy.substring(0, 8)}…'
                            : 'Reported by $_reporterLabel',
                        style: AppTheme.caption.copyWith(
                          color: (_reporterBanned ?? false)
                              ? AppTheme.error
                              : AppTheme.textTertiaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Wrap(
              spacing: AppTheme.spaceSmall,
              runSpacing: AppTheme.spaceSmall,
              children: [
                OutlinedButton.icon(
                  onPressed: _toggleActive,
                  icon: Icon(
                    isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                  ),
                  label: Text(isActive ? 'Remove' : 'Restore'),
                ),
                OutlinedButton.icon(
                  onPressed: _toggleBan,
                  icon: Icon(
                    (_reporterBanned ?? false)
                        ? Icons.person_add_alt_outlined
                        : Icons.block_outlined,
                    size: 16,
                  ),
                  label: Text(
                    (_reporterBanned ?? false)
                        ? 'Unban reporter'
                        : 'Ban reporter',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ),
                ),
                IconButton(
                  onPressed: _confirmDeletePermanently,
                  icon: const Icon(Icons.delete_forever_outlined, size: 20),
                  tooltip: 'Delete permanently',
                  color: AppTheme.textTertiaryOf(context),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
