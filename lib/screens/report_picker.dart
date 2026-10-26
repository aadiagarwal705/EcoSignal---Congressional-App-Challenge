import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/environmental_item.dart';
import '../services/records.dart';
import '../services/reports.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/shimmer.dart';
import '../widgets/record/record_card.dart';

enum _Source { community, official }

class ReportPickerScreen extends StatefulWidget {
  const ReportPickerScreen({super.key});

  @override
  State<ReportPickerScreen> createState() => _ReportPickerScreenState();
}

class _ReportPickerScreenState extends State<ReportPickerScreen> {
  final _searchController = TextEditingController();
  _Source _source = _Source.community;
  late Future<List<EnvironmentalItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final query = _searchController.text.trim();
    if (_source == _Source.community) {
      _future = query.isEmpty
          ? ReportService().getReportsPaginated().then((p) => p.items)
          : ReportService().search(query);
    } else {
      _future = query.isEmpty
          ? RecordService().getRecordsPaginated().then((p) => p.items)
          : RecordService().search(query);
    }
  }

  void _setSource(_Source source) {
    if (source == _source) return;
    setState(() {
      _source = source;
      _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link a Report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMedium,
              AppTheme.spaceMedium,
              AppTheme.spaceMedium,
              0,
            ),
            child: SegmentedButton<_Source>(
              segments: const [
                ButtonSegment(value: _Source.community, label: Text('Community')),
                ButtonSegment(value: _Source.official, label: Text('Official')),
              ],
              selected: {_source},
              onSelectionChanged: (s) => _setSource(s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _source == _Source.community
                    ? 'Search community reports'
                    : 'Search official records',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onSubmitted: (_) => setState(_load),
              onChanged: (_) => setState(_load),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EnvironmentalItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const ShimmerList();
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: _source == _Source.community ? 'No reports found' : 'No records found',
                    message: 'Try a different search term.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return RecordCard(item: item, onTap: () => Navigator.pop(context, item));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
