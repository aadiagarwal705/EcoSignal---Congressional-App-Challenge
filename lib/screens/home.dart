import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_theme.dart';
import '../main.dart' show homeCountyNotifier, mainScreenTabRequestNotifier;
import '../models/community_report.dart';
import '../models/environmental_item.dart';
import '../models/official_record.dart';
import '../services/geo.dart';
import '../services/records.dart';
import '../services/reports.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/shimmer.dart';
import '../widgets/ecoguide/ecoguide_banner.dart';
import '../widgets/ecoguide/open_ecoguide.dart';
import '../widgets/record/record_card.dart';
import 'map_view.dart';
import 'record_detail.dart';
import 'report_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = RecordService();
  late Future<List<OfficialRecord>> _recentFuture;
  late Future<_NearbyResult> _nearbyFuture;

  @override
  void initState() {
    super.initState();
    _recentFuture = _service.getRecent(county: homeCountyNotifier.value);
    _nearbyFuture = _loadNearby();
    homeCountyNotifier.addListener(_onHomeCountyChanged);
  }

  @override
  void dispose() {
    homeCountyNotifier.removeListener(_onHomeCountyChanged);
    super.dispose();
  }

  void _onHomeCountyChanged() => _refresh();

  Future<void> _refresh() async {
    final future = _service.getRecent(county: homeCountyNotifier.value);
    setState(() {
      _recentFuture = future;
      _nearbyFuture = _loadNearby();
    });
    await Future.wait([future, _nearbyFuture]);
  }

  // uses the phone's location to find the county, then sorts what's there by distance.
  // falls back to home county + newest first if there's no location permission
  Future<_NearbyResult> _loadNearby() async {
    final geo = GeoService();
    final position = await geo.getDevicePosition();
    var county = homeCountyNotifier.value;
    if (position != null) {
      final described = await geo.describeLocation(position);
      county = described.county ?? county;
    }
    final results = await Future.wait([
      _service.getRecent(county: county, limit: 40),
      ReportService().getReportsPaginated(counties: county == null ? null : [county], limit: 40),
    ]);
    final items = <EnvironmentalItem>[
      ...results[0] as List<OfficialRecord>,
      ...(results[1] as RecordPage).items,
    ];
    final entries = [
      for (final item in items)
        _NearbyEntry(
          item: item,
          miles: position != null && item.hasLocation
              ? Geolocator.distanceBetween(
                      position.latitude,
                      position.longitude,
                      item.lat!,
                      item.lng!,
                    ) /
                    1609.344
              : null,
        ),
    ];
    if (position != null) {
      entries.sort(
        (a, b) =>
            (a.miles ?? double.infinity).compareTo(b.miles ?? double.infinity),
      );
    } else {
      entries.sort((a, b) => b.item.date.compareTo(a.item.date));
    }
    return _NearbyResult(entries.take(3).toList(), position, county);
  }

  void _open(EnvironmentalItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => item.isOfficial
            ? RecordDetailScreen(record: item as OfficialRecord)
            : ReportDetailScreen(report: item as CommunityReport),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMedium,
          AppTheme.spaceMedium + 2,
          AppTheme.spaceMedium,
          AppTheme.spaceLarge,
        ),
        children: [
          _SearchPill(onTap: () => mainScreenTabRequestNotifier.value = 1),
          const SizedBox(height: AppTheme.spaceMedium + 2),
          const EcoGuideBanner(),
          const SizedBox(height: AppTheme.spaceLarge),
          const _QuickActions(),
          const SizedBox(height: AppTheme.spaceLarge),
          _SectionTitle(
            title: 'Nearby Activity',
            action: 'See All',
            onAction: () => mainScreenTabRequestNotifier.value = 1,
          ),
          FutureBuilder<_NearbyResult>(
            future: _nearbyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 260,
                  child: ShimmerList(count: 3),
                );
              }
              final result = snapshot.data;
              if (result == null || result.entries.isEmpty) {
                return const EmptyState(
                  icon: Icons.near_me_outlined,
                  title: 'Nothing nearby yet',
                  message:
                      'Activity near you will show up here. Try Explore to browse all of Maryland.',
                );
              }
              return Column(
                children: [
                  if (result.position == null)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spaceSmall,
                      ),
                      child: Text(
                        'Turn on location to see distances.',
                        style: AppTheme.subtitle.copyWith(
                          color: AppTheme.textTertiaryOf(context),
                        ),
                      ),
                    ),
                  for (final entry in result.entries) ...[
                    RecordCard(
                      item: entry.item,
                      onTap: () => _open(entry.item),
                      onAsk: () => openEcoGuide(context, item: entry.item),
                      distanceLabel: entry.miles == null
                          ? null
                          : '${entry.miles!.toStringAsFixed(1)} mi away',
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          ValueListenableBuilder<String?>(
            valueListenable: homeCountyNotifier,
            builder: (context, homeCounty, _) => _SectionTitle(
              title: homeCounty == null
                  ? 'Recent Activity'
                  : 'Recent Activity in $homeCounty',
              action: 'See All',
              onAction: () => mainScreenTabRequestNotifier.value = 1,
            ),
          ),
          FutureBuilder<List<OfficialRecord>>(
            future: _recentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 320,
                  child: ShimmerList(count: 4),
                );
              }
              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return EmptyState(
                  icon: Icons.eco_outlined,
                  title: 'No records yet',
                  message: homeCountyNotifier.value == null
                      ? "Once official Maryland environmental records are imported, they'll show up here."
                      : 'No recent records for ${homeCountyNotifier.value} — try Explore, or change your home county in Settings.',
                );
              }
              return Column(
                children: [
                  for (final record in records) ...[
                    RecordCard(
                      item: record,
                      onTap: () => _open(record),
                      onAsk: () => openEcoGuide(context, item: record),
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NearbyEntry {
  final EnvironmentalItem item;
  final double? miles;
  const _NearbyEntry({required this.item, required this.miles});
}

class _NearbyResult {
  final List<_NearbyEntry> entries;
  final LatLng? position;
  final String? county;
  const _NearbyResult(this.entries, this.position, this.county);
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTheme.h3.copyWith(
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
          ),
          TextButton(onPressed: onAction, child: Text('$action  ›')),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.shadowOf(context),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppTheme.textSecondaryOf(context),
            ),
            const SizedBox(width: 10),
            Text(
              'Search city, county, ZIP, or site',
              style: AppTheme.body.copyWith(
                color: AppTheme.textTertiaryOf(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.h3.copyWith(color: AppTheme.textPrimaryOf(context)),
        ),
        const SizedBox(height: AppTheme.spaceSmall + 2),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.travel_explore_rounded,
                label: 'Explore\nRecords',
                color: AppTheme.actionGreen,
                onTap: () => mainScreenTabRequestNotifier.value = 1,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.report_problem_rounded,
                label: 'Report\nIssue',
                color: AppTheme.actionBlue,
                onTap: () => mainScreenTabRequestNotifier.value = 3,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.auto_awesome_rounded,
                label: 'Ask\nEcoGuide',
                color: AppTheme.ai,
                filled: true,
                onTap: () => openEcoGuide(context),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.map_rounded,
                label: 'View\nMap',
                color: AppTheme.actionTeal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium + 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
        decoration: BoxDecoration(
          gradient: filled ? AppTheme.aiGradient : null,
          color: filled ? null : color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium + 2),
          border: filled
              ? null
              : Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 28),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(
                color: filled ? Colors.white : AppTheme.textPrimaryOf(context),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
