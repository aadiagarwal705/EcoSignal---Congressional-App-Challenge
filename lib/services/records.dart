import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/environmental_item.dart';
import '../models/official_record.dart';

class RecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('records');

  // a single county still goes through isEqualTo - whereIn is only needed
  // once there's more than one, and it tops out at 30 values anyway
  Query<Map<String, dynamic>> _whereCounty(Query<Map<String, dynamic>> query, List<String>? counties) {
    if (counties == null || counties.isEmpty) return query;
    return counties.length == 1
        ? query.where('county', isEqualTo: counties.first)
        : query.where('county', whereIn: counties);
  }

  Future<RecordPage> getRecordsPaginated({
    DocumentSnapshot? lastDocument,
    List<String>? counties,
    int limit = AppConstants.pageSize,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _records.orderBy(
        'inspection_date',
        descending: true,
      );
      query = _whereCounty(query, counties);
      query = query.limit(limit);
      if (lastDocument != null) query = query.startAfterDocument(lastDocument);
      final snap = await query.get();
      return (
        items: snap.docs
            .map<EnvironmentalItem>(
              (d) => OfficialRecord.fromMap(d.id, d.data()),
            )
            .toList(),
        lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
        hasMore: snap.docs.length >= limit,
      );
    } catch (_) {
      return (items: <EnvironmentalItem>[], lastDocument: null, hasMore: false);
    }
  }

  Future<OfficialRecord?> getRecord(String id) async {
    try {
      final doc = await _records.doc(id).get();
      if (!doc.exists) return null;
      return OfficialRecord.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<List<EnvironmentalItem>> search(String query, {List<String>? counties}) async {
    try {
      if (query.trim().isEmpty) return [];
      final snap = await _whereCounty(_records, counties).get();
      final needle = query.trim().toLowerCase();
      final matches =
          snap.docs
              .map((d) => OfficialRecord.fromMap(d.id, d.data()))
              .where(
                (r) =>
                    r.siteName.toLowerCase().contains(needle) ||
                    r.county.toLowerCase().contains(needle) ||
                    r.inspectionType.toLowerCase().contains(needle) ||
                    r.address.toLowerCase().contains(needle),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      return matches;
    } catch (_) {
      return [];
    }
  }

  Future<List<OfficialRecord>> getRecent({
    int limit = 6,
    String? county,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _records.orderBy(
        'inspection_date',
        descending: true,
      );
      if (county != null) {
        query = _records
            .where('county', isEqualTo: county)
            .orderBy('inspection_date', descending: true);
      }
      final snap = await query.limit(limit).get();
      return snap.docs
          .map((d) => OfficialRecord.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OfficialRecord>> getAllForMap({List<String>? counties}) async {
    try {
      final snap = await _whereCounty(_records, counties).get();
      return snap.docs
          .map((d) => OfficialRecord.fromMap(d.id, d.data()))
          .where((r) => r.hasLocation)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OfficialRecord>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final results = <OfficialRecord>[];
    for (var i = 0; i < ids.length; i += 30) {
      final batch = ids.sublist(i, (i + 30).clamp(0, ids.length));
      try {
        final snap = await _records
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        results.addAll(
          snap.docs.map((d) => OfficialRecord.fromMap(d.id, d.data())),
        );
      } catch (_) {}
    }
    final byId = {for (final r in results) r.id: r};
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }
}
