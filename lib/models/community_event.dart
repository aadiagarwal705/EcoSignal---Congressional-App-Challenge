import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus {
  active,
  removed;

  String get dbValue => name;

  static EventStatus fromDb(String? value) =>
      EventStatus.values.firstWhere((e) => e.name == value, orElse: () => EventStatus.active);
}

class CommunityEvent {
  final String id;
  final String title;
  final String description;
  final String organizerUid;
  final String organizerName;
  final DateTime dateTime;
  final String locationLabel;
  final String county;
  final double lat;
  final double lng;
  final String? reportId;
  final String? reportLabel;
  final String linkedItemType;
  final List<String> attendeeUids;
  final DateTime createdAt;
  final EventStatus status;

  const CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerUid,
    required this.organizerName,
    required this.dateTime,
    required this.locationLabel,
    required this.county,
    required this.lat,
    required this.lng,
    this.reportId,
    this.reportLabel,
    this.linkedItemType = 'report',
    required this.attendeeUids,
    required this.createdAt,
    required this.status,
  });

  bool get linksToRecord => linkedItemType == 'record';

  int get attendeeCount => attendeeUids.length;
  bool get isPast => dateTime.isBefore(DateTime.now());
  bool isAttending(String? uid) => uid != null && attendeeUids.contains(uid);

  factory CommunityEvent.fromMap(String id, Map<String, dynamic> data) {
    return CommunityEvent(
      id: id,
      title: data['title'] ?? 'Untitled event',
      description: data['description'] ?? '',
      organizerUid: data['organizer_uid'] ?? '',
      organizerName: data['organizer_name'] ?? 'A community member',
      dateTime: (data['date_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      locationLabel: data['location_label'] ?? '',
      county: data['county'] ?? 'Unknown',
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      reportId: data['report_id'] as String?,
      reportLabel: data['report_label'] as String?,
      linkedItemType: data['linked_item_type'] as String? ?? 'report',
      attendeeUids: (data['attendee_uids'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: EventStatus.fromDb(data['status'] as String?),
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'title': title,
    'description': description,
    'organizer_uid': organizerUid,
    'organizer_name': organizerName,
    'date_time': Timestamp.fromDate(dateTime),
    'location_label': locationLabel,
    'county': county,
    'lat': lat,
    'lng': lng,
    'report_id': reportId,
    'report_label': reportLabel,
    'linked_item_type': linkedItemType,
    'attendee_uids': <String>[],
    'created_at': FieldValue.serverTimestamp(),
    'status': status.dbValue,
  };
}
