import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../models/community_event.dart';
import '../models/community_report.dart';

class AdminService {
  final _firestore = FirebaseFirestore.instance;

  Stream<bool> get isAdminStream {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield false;
        return;
      }
      yield* _firestore
          .collection('admins')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.data()?['is_active'] == true);
    });
  }

  Future<List<CommunityReport>> getAllReports({int limit = 100}) async {
    try {
      final snap = await _firestore
          .collection('community_reports')
          .orderBy('submitted_at', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => CommunityReport.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setReportStatus(String reportId, ReportStatus status) =>
      _firestore.collection('community_reports').doc(reportId).update({
        'status': status.dbValue,
      });

  Future<void> deleteReportPermanently(String reportId) =>
      _firestore.collection('community_reports').doc(reportId).delete();

  Future<void> setUserBanned(String uid, bool banned) => _firestore
      .collection('users')
      .doc(uid)
      .set({'is_banned': banned}, SetOptions(merge: true));

  Future<bool> isUserBanned(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['is_banned'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUserLabel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return null;
      return (data['display_name'] as String?) ?? (data['email'] as String?);
    } catch (_) {
      return null;
    }
  }

  Future<List<CommunityEvent>> getAllEvents({int limit = 100}) async {
    try {
      final snap = await _firestore
          .collection('community_events')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => CommunityEvent.fromMap(d.id, d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setEventStatus(String eventId, EventStatus status) =>
      _firestore.collection('community_events').doc(eventId).update({'status': status.dbValue});

  Future<void> deleteEventPermanently(String eventId) =>
      _firestore.collection('community_events').doc(eventId).delete();
}
