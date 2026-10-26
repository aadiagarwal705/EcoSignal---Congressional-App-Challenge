import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_theme.dart';
import '../models/community_event.dart';
import '../models/community_report.dart';
import '../models/environmental_item.dart';
import '../models/official_record.dart';
import '../services/events.dart';
import '../services/records.dart';
import '../services/reports.dart';
import '../widgets/ecoguide/ecoguide_strip.dart';
import '../widgets/ecoguide/open_ecoguide.dart';
import '../widgets/events/event_card.dart';
import '../widgets/map/map_controls.dart';
import '../widgets/map/map_legend.dart';
import '../widgets/map/map_pin.dart';
import '../widgets/record/record_card.dart';
import 'event_detail.dart';
import 'record_detail.dart';
import 'report_detail.dart';

const _initialCenter = LatLng(39.15, -76.85);
const _initialZoom = 9.2;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _recordService = RecordService();
  final _reportService = ReportService();
  final _eventService = EventService();
  final _mapController = MapController();

  MapFilter _filter = MapFilter.all;
  Set<String> _selectedCounties = {};
  bool _loading = true;
  List<OfficialRecord> _records = [];
  List<CommunityReport> _reports = [];
  List<CommunityEvent> _events = [];

  bool get _wantsRecords => _filter == MapFilter.all || _filter == MapFilter.official;
  bool get _wantsReports => _filter == MapFilter.all || _filter == MapFilter.community;
  bool get _wantsEvents => _filter == MapFilter.all || _filter == MapFilter.events;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<String>? get _counties => _selectedCounties.isEmpty ? null : _selectedCounties.toList();

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _wantsRecords ? _recordService.getAllForMap(counties: _counties) : Future.value(<OfficialRecord>[]),
      _wantsReports ? _reportService.getAllForMap(counties: _counties) : Future.value(<CommunityReport>[]),
      _wantsEvents
          ? _eventService.getEventsPaginated(counties: _counties, limit: 200).then((p) => p.items)
          : Future.value(<CommunityEvent>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _records = results[0] as List<OfficialRecord>;
      _reports = results[1] as List<CommunityReport>;
      _events = results[2] as List<CommunityEvent>;
      _loading = false;
    });
  }

  void _openItem(EnvironmentalItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => item.isOfficial
            ? RecordDetailScreen(record: item as OfficialRecord)
            : ReportDetailScreen(report: item as CommunityReport),
      ),
    );
  }

  void _showPreview(EnvironmentalItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: SafeArea(
          top: false,
          child: RecordCard(
            item: item,
            onTap: () => _openItem(item),
            onAsk: () {
              Navigator.pop(context);
              openEcoGuide(context, item: item);
            },
          ),
        ),
      ),
    );
  }

  void _showEventPreview(CommunityEvent event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: SafeArea(
          top: false,
          child: EventCard(
            event: event,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
            },
          ),
        ),
      ),
    );
  }

  void _askAboutArea() {
    final center = _mapController.camera.center;
    final place = switch (_selectedCounties.length) {
      0 => 'the Maryland area around ${center.latitude.toStringAsFixed(3)}, ${center.longitude.toStringAsFixed(3)}',
      1 => '${_selectedCounties.first} County, Maryland',
      _ => '${_selectedCounties.join(', ')} counties, Maryland',
    };
    openEcoGuide(
      context,
      question:
          "I'm looking at the EcoSignal map for $place. It shows ${_records.length} official MDE inspection "
          '${_reports.length} community reports, and ${_events.length} community events being organized. What '
          'environmental concerns or patterns should I know about in this area, and what can residents do?',
    );
  }

  List<Marker> get _markers {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return [
      for (final record in _records)
        Marker(
          point: LatLng(record.lat!, record.lng!),
          width: 34,
          height: 34,
          child: EnvironmentalMarkerPin(
            icon: record.icon,
            color: AppTheme.officialBadge,
            onTap: () => _showPreview(record),
          ),
        ),
      for (final report in _reports)
        Marker(
          point: LatLng(report.lat!, report.lng!),
          width: 34,
          height: 34,
          child: EnvironmentalMarkerPin(
            icon: report.icon,
            color: report.submittedBy == myUid ? AppTheme.myReportBadge : AppTheme.communityBadge,
            onTap: () => _showPreview(report),
          ),
        ),
      for (final event in _events)
        Marker(
          point: LatLng(event.lat, event.lng),
          width: 34,
          height: 34,
          child: EnvironmentalMarkerPin(
            icon: Icons.volunteer_activism_rounded,
            color: AppTheme.eventBadge,
            onTap: () => _showEventPreview(event),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Map'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCFE6F6), Color(0xFFEAF5EE)],
                ),
              ),
            ),
            Image.asset(
              'assets/images/header_banner.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ],
        ),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              minZoom: 7,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecosignal.md',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 50,
                  size: const Size(38, 38),
                  markers: _markers,
                  builder: (context, markers) =>
                      ClusterBubble(count: markers.length),
                ),
              ),
            ],
          ),
          if (_loading)
            const Positioned(top: 12, right: 12, child: LoadingChip()),
          Positioned(
            left: AppTheme.spaceMedium,
            right: AppTheme.spaceMedium,
            top: AppTheme.spaceMedium,
            child: MapControls(
              filter: _filter,
              selectedCounties: _selectedCounties,
              onFilterChanged: (f) => setState(() {
                _filter = f;
                _load();
              }),
              onCountiesChanged: (counties) => setState(() {
                _selectedCounties = counties;
                _load();
              }),
            ),
          ),
          Positioned(
            bottom: AppTheme.spaceMedium,
            left: AppTheme.spaceMedium,
            right: AppTheme.spaceMedium,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EcoGuideStrip(
                  title: 'Ask EcoGuide about this area',
                  subtitle:
                      "What's going on around here, and what can be done?",
                  onTap: _askAboutArea,
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                const MapLegend(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
