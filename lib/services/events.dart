import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/community_event.dart';

typedef EventPage = ({List<CommunityEvent> items, DocumentSnapshot? lastDocument, bool hasMore});

class EventService {
  final _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _events => _firestore.collection('community_events');

  String newEventId() => _events.doc().id;

  Future<void> submitEvent(String id, CommunityEvent event) => _events.doc(id).set(event.toCreateMap());

  Query<Map<String, dynamic>> _whereCounty(Query<Map<String, dynamic>> query, List<String>? counties) {
    if (counties == null || counties.isEmpty) return query;
    return counties.length == 1
        ? query.where('county', isEqualTo: counties.first)
        : query.where('county', whereIn: counties);
  }

  // newest-posted first, same as the reports feed - the date/time of the event
  // itself is shown on each card, so this isn't "soonest first"
  Future<EventPage> getEventsPaginated({
    DocumentSnapshot? lastDocument,
    List<String>? counties,
    int limit = AppConstants.pageSize,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _whereCounty(
        _events.where('status', isEqualTo: 'active'),
        counties,
      ).orderBy('created_at', descending: true);
      query = query.limit(limit);
      if (lastDocument != null) query = query.startAfterDocument(lastDocument);
      // forces a real server round trip - a one-shot get() right at app launch can otherwise
      // silently fall back to an empty local cache before the Firestore channel connects
      final snap = await query.get(const GetOptions(source: Source.server));
      return (
        items: snap.docs.map((d) => CommunityEvent.fromMap(d.id, d.data())).toList(),
        lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
        hasMore: snap.docs.length >= limit,
      );
    } catch (_) {
      return (items: <CommunityEvent>[], lastDocument: null, hasMore: false);
    }
  }

  Future<CommunityEvent?> getEvent(String id) async {
    try {
      final doc = await _events.doc(id).get(const GetOptions(source: Source.server));
      if (!doc.exists) return null;
      return CommunityEvent.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> setAttending(String eventId, String uid, bool attending) => _events.doc(eventId).update({
    'attendee_uids': attending ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
  });

  Future<void> deleteEvent(String id) => _events.doc(id).delete();
}
