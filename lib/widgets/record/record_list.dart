import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/environmental_item.dart';
import '../common/empty_state.dart';
import '../common/shimmer.dart';
import 'record_card.dart';

class RecordListView extends StatefulWidget {
  final Future<RecordPage> Function({DocumentSnapshot? lastDocument})
  dataSource;

  final Future<List<EnvironmentalItem>> Function(String query)? searchSource;
  final TextEditingController? searchController;

  final void Function(EnvironmentalItem item) onTap;
  final void Function(EnvironmentalItem item)? onAsk;
  final Widget? header;

  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  const RecordListView({
    super.key,
    required this.dataSource,
    required this.onTap,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.onAsk,
    this.header,
    this.searchSource,
    this.searchController,
  });

  @override
  State<RecordListView> createState() => _RecordListViewState();
}

class _RecordListViewState extends State<RecordListView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<EnvironmentalItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _query = '';

  bool get _isSearching => _query.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _query = widget.searchController?.text.trim() ?? '';
    widget.searchController?.addListener(_onSearchChanged);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    widget.searchController?.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      final newQuery = widget.searchController!.text.trim();
      if (newQuery == _query) return;
      _query = newQuery;
      _loadInitial();
    });
  }

  void _onScroll() {
    if (_isSearching) return;
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    if (_isSearching) {
      final results = await widget.searchSource!(_query);
      if (!mounted) return;
      setState(() {
        _items = results;
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    final page = await widget.dataSource();
    if (!mounted) return;
    setState(() {
      _items = page.items;
      _lastDocument = page.lastDocument;
      _isLoading = false;
      _hasMore = page.hasMore;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final page = await widget.dataSource(lastDocument: _lastDocument);
    if (!mounted) return;
    setState(() {
      _items = [..._items, ...page.items];
      _lastDocument = page.lastDocument ?? _lastDocument;
      _isLoadingMore = false;
      _hasMore = page.hasMore;
    });
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.header;

    if (_isLoading || _items.isEmpty) {
      final body = _isLoading
          ? const ShimmerList()
          : EmptyState(
              icon: widget.emptyIcon,
              title: widget.emptyTitle,
              message: widget.emptyMessage,
            );
      if (header == null) return body;
      return Column(
        children: [
          header,
          Expanded(child: body),
        ],
      );
    }

    final offset = header == null ? 0 : 1;
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          bottom: AppTheme.spaceMedium,
          top: header == null ? AppTheme.spaceMedium : 0,
        ),
        itemCount: _items.length + offset + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (header != null && index == 0) return header;
          final i = index - offset;
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _items[i];
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMedium,
              0,
              AppTheme.spaceMedium,
              AppTheme.spaceMedium,
            ),
            child: RecordCard(
              item: item,
              onTap: () => widget.onTap(item),
              onAsk: widget.onAsk == null ? null : () => widget.onAsk!(item),
            ),
          );
        },
      ),
    );
  }
}
