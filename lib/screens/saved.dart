import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../main.dart' show authNotifier;
import '../models/community_report.dart';
import '../models/environmental_item.dart';
import '../models/official_record.dart';
import '../services/records.dart';
import '../services/reports.dart';
import '../services/user_profile.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/shimmer.dart';
import '../widgets/ecoguide/open_ecoguide.dart';
import '../widgets/record/record_card.dart';
import 'record_detail.dart';
import 'report_detail.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: ValueListenableBuilder<User?>(
        valueListenable: authNotifier,
        builder: (context, user, _) {
          return _SavedList(key: ValueKey(user?.uid ?? 'none'));
        },
      ),
    );
  }
}

class _SavedList extends StatefulWidget {
  const _SavedList({super.key});

  @override
  State<_SavedList> createState() => _SavedListState();
}

class _SavedListState extends State<_SavedList> {
  final Map<String, EnvironmentalItem> _cache = {};
  StreamSubscription<SavedIds>? _subscription;
  SavedIds? _lastIds;
  List<EnvironmentalItem>? _items;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _subscription = UserProfileService().savedIdsStream.listen(
      _onIdsChanged,
      onError: (_) {
        if (mounted) setState(() => _items ??= []);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<EnvironmentalItem> _sorted() =>
      _cache.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  // unsaving something removes it instantly; only newly-saved ids get fetched.
  // _generation exists because a slow fetch from an older call shouldn't be able to
  // stomp on a newer one that already finished
  Future<void> _onIdsChanged(SavedIds ids) async {
    _lastIds = ids;
    final generation = ++_generation;

    final wanted = {
      ...ids.recordIds.map((id) => 'record_$id'),
      ...ids.reportIds.map((id) => 'report_$id'),
    };
    _cache.removeWhere((key, _) => !wanted.contains(key));
    if (_items != null && mounted) {
      setState(() {
        _items = _sorted();
      });
    }

    final missingRecords = ids.recordIds
        .where((id) => !_cache.containsKey('record_$id'))
        .toList();
    final missingReports = ids.reportIds
        .where((id) => !_cache.containsKey('report_$id'))
        .toList();
    if (missingRecords.isNotEmpty || missingReports.isNotEmpty) {
      final results = await Future.wait([
        RecordService().getByIds(missingRecords),
        ReportService().getByIds(missingReports),
      ]);
      if (!mounted || generation != _generation) return;
      for (final record in results[0]) {
        _cache['record_${record.id}'] = record;
      }
      for (final report in results[1]) {
        _cache['report_${report.id}'] = report;
      }
    }

    if (!mounted || generation != _generation) return;
    setState(() {
      _items = _sorted();
    });
  }

  Future<void> _refresh() async {
    final ids = _lastIds;
    if (ids == null) return;
    _cache.clear();
    await _onIdsChanged(ids);
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
    final items = _items;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: items == null
          ? const ShimmerList()
          : items.isEmpty
          ? ListView(
              children: const [
                EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Nothing saved yet',
                  message:
                      'Tap the bookmark icon on a record or report to keep it here.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTheme.spaceMedium),
              itemBuilder: (context, index) {
                final item = items[index];
                return RecordCard(
                  item: item,
                  onTap: () => _open(item),
                  onAsk: () => openEcoGuide(context, item: item),
                );
              },
            ),
    );
  }
}
