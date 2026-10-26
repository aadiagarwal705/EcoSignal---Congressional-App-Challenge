import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../main.dart' show authNotifier;
import '../models/community_event.dart';
import '../services/events.dart';
import '../widgets/common/county_dropdown.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/shimmer.dart';
import '../widgets/events/event_card.dart';
import '../widgets/events/guest_signin_sheet.dart';
import 'event_detail.dart';
import 'new_event.dart';

class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  final _service = EventService();
  final _scrollController = ScrollController();
  Set<String> _counties = {};

  List<CommunityEvent> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  List<String>? get _countyList => _counties.isEmpty ? null : _counties.toList();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    final page = await _service.getEventsPaginated(counties: _countyList);
    if (!mounted) return;
    setState(() {
      _events = page.items;
      _lastDocument = page.lastDocument;
      _hasMore = page.hasMore;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final page = await _service.getEventsPaginated(counties: _countyList, lastDocument: _lastDocument);
    if (!mounted) return;
    setState(() {
      _events = [..._events, ...page.items];
      _lastDocument = page.lastDocument ?? _lastDocument;
      _hasMore = page.hasMore;
      _isLoadingMore = false;
    });
  }

  Future<void> _organize() async {
    final user = authNotifier.value;
    final isGuest = user == null || user.isAnonymous;
    if (isGuest) {
      final signedIn = await showGuestSignInSheet(
        context,
        message: 'Create an account so other members know who is organizing.',
      );
      if (!signedIn || !mounted) return;
    }
    if (!mounted) return;
    final posted = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const NewEventScreen()));
    if (posted == true) _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.spaceMedium, AppTheme.spaceMedium, AppTheme.spaceMedium, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _organize,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Organize an Event'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.eventBadge,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          child: CountyDropdown(
            value: _counties,
            onChanged: (counties) => setState(() {
              _counties = counties;
              _loadInitial();
            }),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitial,
            child: _isLoading
                ? const ShimmerList()
                : _events.isEmpty
                ? ListView(
                    children: const [
                      EmptyState(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Nothing organized yet',
                        message: 'Be the first to organize a cleanup or help event in your area.',
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    itemCount: _events.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceMedium),
                    itemBuilder: (context, index) {
                      if (index >= _events.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final event = _events[index];
                      return EventCard(
                        event: event,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
                          _loadInitial();
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
