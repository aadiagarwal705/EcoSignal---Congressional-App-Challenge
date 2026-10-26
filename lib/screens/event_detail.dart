import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_theme.dart';
import '../main.dart' show authNotifier;
import '../models/community_event.dart';
import '../services/admin_tools.dart';
import '../services/events.dart';
import '../services/records.dart';
import '../services/reports.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/events/attend_button.dart';
import '../widgets/events/guest_signin_sheet.dart';
import 'record_detail.dart';
import 'report_detail.dart';

class EventDetailScreen extends StatefulWidget {
  final CommunityEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late CommunityEvent _event = widget.event;
  bool _busy = false;
  bool _deleting = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _isGuest => authNotifier.value == null || authNotifier.value!.isAnonymous;
  bool get _isOrganizer => _uid != null && _uid == _event.organizerUid;
  bool _openingReport = false;

  Future<void> _openLinkedReport() async {
    final itemId = _event.reportId;
    if (itemId == null || _openingReport) return;
    setState(() => _openingReport = true);
    if (_event.linksToRecord) {
      final record = await RecordService().getRecord(itemId);
      if (!mounted) return;
      setState(() => _openingReport = false);
      if (record == null) {
        showAppSnackBar(context, 'That record is no longer available.', type: SnackType.info);
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => RecordDetailScreen(record: record)));
      return;
    }
    final report = await ReportService().getReport(itemId);
    if (!mounted) return;
    setState(() => _openingReport = false);
    if (report == null) {
      showAppSnackBar(context, 'That report is no longer available.', type: SnackType.info);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)));
  }

  Future<void> _toggleAttending() async {
    if (_isGuest) {
      final signedIn = await showGuestSignInSheet(
        context,
        message: 'Create an account so the organizer knows who to expect.',
      );
      if (!signedIn || !mounted) return;
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final attending = _event.isAttending(uid);
    setState(() => _busy = true);
    try {
      await EventService().setAttending(_event.id, uid, !attending);
      if (!mounted) return;
      setState(() {
        _event = CommunityEvent(
          id: _event.id,
          title: _event.title,
          description: _event.description,
          organizerUid: _event.organizerUid,
          organizerName: _event.organizerName,
          dateTime: _event.dateTime,
          locationLabel: _event.locationLabel,
          county: _event.county,
          lat: _event.lat,
          lng: _event.lng,
          reportId: _event.reportId,
          reportLabel: _event.reportLabel,
          linkedItemType: _event.linkedItemType,
          attendeeUids: attending
              ? (List.of(_event.attendeeUids)..remove(uid))
              : (List.of(_event.attendeeUids)..add(uid)),
          createdAt: _event.createdAt,
          status: _event.status,
        );
      });
    } catch (e) {
      if (mounted) showAppSnackBar(context, "Couldn't update that: $e", type: SnackType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this event?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await EventService().deleteEvent(_event.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, "Couldn't remove the event: $e", type: SnackType.error);
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final point = LatLng(event.lat, event.lng);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        actions: [
          if (_isOrganizer)
            IconButton(
              onPressed: _deleting ? null : _confirmDelete,
              icon: _deleting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline_rounded),
              tooltip: 'Remove event',
            )
          else
            StreamBuilder<bool>(
              stream: AdminService().isAdminStream,
              builder: (context, snapshot) {
                if (snapshot.data != true) return const SizedBox.shrink();
                return IconButton(
                  onPressed: _deleting ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove event (admin)',
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppTheme.eventBadge.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.eventBadge, size: 26),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: AppTheme.h2.copyWith(color: AppTheme.textPrimaryOf(context))),
                    const SizedBox(height: 2),
                    Text('Organized by ${event.organizerName}', style: AppTheme.subtitle.copyWith(color: AppTheme.textSecondaryOf(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.shadowOf(context),
            ),
            child: AttendButton(
              count: event.attendeeCount,
              attending: event.isAttending(_uid),
              busy: _busy,
              onTap: _toggleAttending,
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
                Text('WHEN', style: AppTheme.caption.copyWith(color: AppTheme.textTertiaryOf(context))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 18, color: AppTheme.textSecondaryOf(context)),
                    const SizedBox(width: 8),
                    Text(formatEventWhen(event.dateTime), style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          if (event.description.isNotEmpty) ...[
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
                  Text('DETAILS', style: AppTheme.caption.copyWith(color: AppTheme.textTertiaryOf(context))),
                  const SizedBox(height: 6),
                  Text(event.description, style: AppTheme.body.copyWith(color: AppTheme.textPrimaryOf(context))),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
          ],

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
                Text('LOCATION', style: AppTheme.caption.copyWith(color: AppTheme.textTertiaryOf(context))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 18, color: AppTheme.textSecondaryOf(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${event.locationLabel} · ${event.county}', style: AppTheme.body.copyWith(color: AppTheme.textPrimaryOf(context))),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: SizedBox(
                    height: 140,
                    child: IgnorePointer(
                      child: FlutterMap(
                        options: MapOptions(initialCenter: point, initialZoom: 13),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ecosignal.md',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: point,
                                width: 34,
                                height: 34,
                                child: const Icon(Icons.location_pin, color: AppTheme.eventBadge, size: 34),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (event.reportId != null) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onTap: _openLinkedReport,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: (event.linksToRecord ? AppTheme.officialBadge : AppTheme.communityBadge).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, color: event.linksToRecord ? AppTheme.officialBadge : AppTheme.communityBadge),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.linksToRecord
                            ? 'For an official record: ${event.reportLabel ?? "view record"}'
                            : 'For a reported issue: ${event.reportLabel ?? "view report"}',
                        style: AppTheme.body.copyWith(color: AppTheme.textPrimaryOf(context)),
                      ),
                    ),
                    _openingReport
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.chevron_right_rounded, color: event.linksToRecord ? AppTheme.officialBadge : AppTheme.communityBadge),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
