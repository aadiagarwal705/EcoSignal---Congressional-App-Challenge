import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef SavedIds = ({List<String> recordIds, List<String> reportIds});

class UserProfileService {
  final _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _prefsRef(String uid) =>
      _firestore.collection('user_preferences').doc(uid);

  Future<String?> getHomeCounty() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final doc = await _prefsRef(uid).get();
      return doc.data()?['home_county'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> setHomeCounty(String county) async {
    final uid = _uid;
    if (uid == null) return;
    await _prefsRef(uid).set({
      'home_county': county,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _toggleSaved({
    required String field,
    required String id,
    required bool save,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _prefsRef(uid).set({
      field: save ? FieldValue.arrayUnion([id]) : FieldValue.arrayRemove([id]),
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setRecordSaved(String recordId, bool save) =>
      _toggleSaved(field: 'saved_record_ids', id: recordId, save: save);

  Future<void> setReportSaved(String reportId, bool save) =>
      _toggleSaved(field: 'saved_report_ids', id: reportId, save: save);

  Stream<bool> _containsStream(String id, String field) {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield false;
        return;
      }
      yield* _prefsRef(user.uid).snapshots().map(
        (snap) =>
            List<String>.from(snap.data()?[field] ?? const []).contains(id),
      );
    });
  }

  Stream<bool> isRecordSavedStream(String recordId) =>
      _containsStream(recordId, 'saved_record_ids');
  Stream<bool> isReportSavedStream(String reportId) =>
      _containsStream(reportId, 'saved_report_ids');

  Future<SavedIds> getSavedIds() async {
    final uid = _uid;
    if (uid == null) return (recordIds: <String>[], reportIds: <String>[]);
    try {
      final doc = await _prefsRef(uid).get();
      final data = doc.data();
      return (
        recordIds: List<String>.from(data?['saved_record_ids'] ?? const []),
        reportIds: List<String>.from(data?['saved_report_ids'] ?? const []),
      );
    } catch (_) {
      return (recordIds: <String>[], reportIds: <String>[]);
    }
  }

  Stream<SavedIds> get savedIdsStream {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield (recordIds: <String>[], reportIds: <String>[]);
        return;
      }
      yield* _prefsRef(user.uid).snapshots().map((snap) {
        final data = snap.data();
        return (
          recordIds: List<String>.from(data?['saved_record_ids'] ?? const []),
          reportIds: List<String>.from(data?['saved_report_ids'] ?? const []),
        );
      });
    });
  }
}
