import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/community_report.dart';
import '../models/environmental_item.dart';
import '../models/official_record.dart';
import '../services/records.dart';
import '../services/reports.dart';
import '../widgets/common/county_dropdown.dart';
import '../widgets/ecoguide/ecoguide_strip.dart';
import '../widgets/ecoguide/open_ecoguide.dart';
import '../widgets/record/record_list.dart';
import 'record_detail.dart';
import 'report_detail.dart';

enum _ExploreFilter { all, official, community }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _recordService = RecordService();
  final _reportService = ReportService();
  final _searchController = TextEditingController();
  Set<String> _selectedCounties = {};
  _ExploreFilter _filter = _ExploreFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<String>? get _counties => _selectedCounties.isEmpty ? null : _selectedCounties.toList();

  Future<RecordPage> _dataSource({DocumentSnapshot? lastDocument}) {
    switch (_filter) {
      case _ExploreFilter.official:
        return _recordService.getRecordsPaginated(counties: _counties, lastDocument: lastDocument);
      case _ExploreFilter.community:
        return _reportService.getReportsPaginated(counties: _counties, lastDocument: lastDocument);
      case _ExploreFilter.all:
        return _mergedFirstPage();
    }
  }

  Future<RecordPage> _mergedFirstPage() async {
    final results = await Future.wait([
      _recordService.getRecordsPaginated(counties: _counties, limit: 20),
      _reportService.getReportsPaginated(counties: _counties, limit: 20),
    ]);
    final merged = [...results[0].items, ...results[1].items]..sort((a, b) => b.date.compareTo(a.date));
    return (items: merged, lastDocument: null, hasMore: false);
  }

  Future<List<EnvironmentalItem>> _search(String query) async {
    switch (_filter) {
      case _ExploreFilter.official:
        return _recordService.search(query, counties: _counties);
      case _ExploreFilter.community:
        return _reportService.search(query, counties: _counties);
      case _ExploreFilter.all:
        final results = await Future.wait([
          _recordService.search(query, counties: _counties),
          _reportService.search(query, counties: _counties),
        ]);
        return [...results[0], ...results[1]]..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecordListView(
      key: ValueKey('$_filter-$_selectedCounties'),
      searchController: _searchController,
      dataSource: _dataSource,
      searchSource: _search,
      onTap: _openItem,
      onAsk: (item) => openEcoGuide(context, item: item),
      emptyIcon: Icons.search_off_rounded,
      emptyTitle: 'No results found',
      emptyMessage: 'Try a different search term, filter, or county.',
      header: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMedium, AppTheme.spaceMedium, AppTheme.spaceMedium, AppTheme.spaceSmall),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Search records', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
            child: SegmentedButton<_ExploreFilter>(
              segments: const [
                ButtonSegment(value: _ExploreFilter.all, label: Text('All')),
                ButtonSegment(value: _ExploreFilter.official, label: Text('Official')),
                ButtonSegment(value: _ExploreFilter.community, label: Text('Community')),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) => setState(() => _filter = selection.first),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
            child: CountyDropdown(
              value: _selectedCounties,
              onChanged: (counties) => setState(() => _selectedCounties = counties),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
            child: EcoGuideStrip(
              title: 'Ask EcoGuide about any event',
              subtitle: 'Tap "Ask EcoGuide" on any record below.',
              onTap: () => openEcoGuide(context),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
        ],
      ),
    );
  }
}
