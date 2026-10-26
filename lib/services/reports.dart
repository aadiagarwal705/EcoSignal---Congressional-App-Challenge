import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/community_report.dart';
import '../models/environmental_item.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('community_reports');

  Query<Map<String, dynamic>> _whereCounty(Query<Map<String, dynamic>> query, List<String>? counties) {
    if (counties == null || counties.isEmpty) return query;
    return counties.length == 1
        ? query.where('county', isEqualTo: counties.first)
        : query.where('county', whereIn: counties);
  }

  String newReportId() => _reports.doc().id;

  Future<void> submitReport(String id, CommunityReport report) =>
      _reports.doc(id).set(report.toCreateMap());

  Future<RecordPage> getReportsPaginated({
    DocumentSnapshot? lastDocument,
    List<String>? counties,
    int limit = AppConstants.pageSize,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _whereCounty(
        _reports.where('status', isEqualTo: 'active'),
        counties,
      ).orderBy('submitted_at', descending: true);
      query = query.limit(limit);
      if (lastDocument != null) query = query.startAfterDocument(lastDocument);
      final snap = await query.get();
      return (
        items: snap.docs
            .map<EnvironmentalItem>(
              (d) => CommunityReport.fromMap(d.id, d.data()),
            )
            .toList(),
        lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
        hasMore: snap.docs.length >= limit,
      );
    } catch (_) {
      return (items: <EnvironmentalItem>[], lastDocument: null, hasMore: false);
    }
  }

  Future<CommunityReport?> getReport(String id) async {
    try {
      final doc = await _reports.doc(id).get();
      if (!doc.exists) return null;
      return CommunityReport.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<List<EnvironmentalItem>> search(String query, {List<String>? counties}) async {
    try {
      if (query.trim().isEmpty) return [];
      final snap = await _whereCounty(_reports.where('status', isEqualTo: 'active'), counties).get();
      final needle = query.trim().toLowerCase();
      final matches =
          snap.docs
              .map((d) => CommunityReport.fromMap(d.id, d.data()))
              .where(
                (r) =>
                    r.description.toLowerCase().contains(needle) ||
                    r.county.toLowerCase().contains(needle) ||
                    r.category.label.toLowerCase().contains(needle) ||
                    r.locationLabel.toLowerCase().contains(needle),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      return matches;
    } catch (_) {
      return [];
    }
  }

  Future<List<CommunityReport>> getMyReports(String uid) async {
    try {
      final snap = await _reports
          .where('submitted_by', isEqualTo: uid)
          .orderBy('submitted_at', descending: true)
          .get();
      return snap.docs
          .map((d) => CommunityReport.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteReport(String id) => _reports.doc(id).delete();

  Future<List<CommunityReport>> getAllForMap({List<String>? counties}) async {
    try {
      final snap = await _whereCounty(_reports.where('status', isEqualTo: 'active'), counties).get();
      return snap.docs
          .map((d) => CommunityReport.fromMap(d.id, d.data()))
          .where((r) => r.hasLocation)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CommunityReport>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final results = <CommunityReport>[];
    for (var i = 0; i < ids.length; i += 30) {
      final batch = ids.sublist(i, (i + 30).clamp(0, ids.length));
      try {
        final snap = await _reports
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        results.addAll(
          snap.docs.map((d) => CommunityReport.fromMap(d.id, d.data())),
        );
      } catch (_) {}
    }
    final byId = {for (final r in results) r.id: r};
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }
}
