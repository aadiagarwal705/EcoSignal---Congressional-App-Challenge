import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? displayName;
  final String? photoUrl;
  final String? email;
  final String? homeCounty;
  final List<String> savedRecordIds;
  final List<String> savedReportIds;
  final int reportCount;
  final DateTime? joinedAt;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.email,
    required this.homeCounty,
    required this.savedRecordIds,
    required this.savedReportIds,
    required this.reportCount,
    required this.joinedAt,
  });

  bool get hasHomeCounty => homeCounty != null && homeCounty!.isNotEmpty;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      displayName: data['display_name'] as String?,
      photoUrl: data['photo_url'] as String?,
      email: data['email'] as String?,
      homeCounty: data['home_county'] as String?,
      savedRecordIds: List<String>.from(data['saved_record_ids'] ?? const []),
      savedReportIds: List<String>.from(data['saved_report_ids'] ?? const []),
      reportCount: (data['report_count'] as num?)?.toInt() ?? 0,
      joinedAt: (data['joined_at'] as Timestamp?)?.toDate(),
    );
  }
}
