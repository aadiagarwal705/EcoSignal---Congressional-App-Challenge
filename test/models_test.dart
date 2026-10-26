import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecosignal_project/constants/app_constants.dart';
import 'package:ecosignal_project/models/chat_message.dart';
import 'package:ecosignal_project/models/chat_thread.dart';
import 'package:ecosignal_project/models/community_report.dart';
import 'package:ecosignal_project/models/official_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfficialRecord.fromMap', () {
    test('maps all fields', () {
      final record = OfficialRecord.fromMap('abc123', {
        'site_name': 'Test Site',
        'address': '1 Main St',
        'city_state_zip': 'Columbia,MD,21044',
        'county': 'Howard',
        'inspection_type': 'Sediment_Erosion',
        'inspection_reason': 'Routine Scheduled',
        'inspection_date': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'site_status': 'Compliance',
        'site_condition': 'Satisfactory',
        'recommended_actions': 'None',
        'permit_no': 'ABC-1',
        'npdes_no': 'N/A',
        'source_url': 'https://example.com',
        'lat': 39.2,
        'lng': -76.8,
      });

      expect(record.id, 'abc123');
      expect(record.title, 'Test Site');
      expect(record.categoryLabel, 'Sediment Erosion');
      expect(record.cityStateZip, 'Columbia, MD, 21044');
      expect(record.isOfficial, isTrue);
      expect(record.locationApproximate, isFalse);
      expect(record.hasLocation, isTrue);
    });

    test('uses defaults for missing fields', () {
      final record = OfficialRecord.fromMap('xyz', {'county': 'Carroll'});
      expect(record.siteName, 'Unnamed site');
      expect(record.permitNo, 'N/A');
      expect(record.hasLocation, isFalse);
    });
  });

  group('CommunityReport', () {
    test('title is the category, label is the description', () {
      final report = CommunityReport.fromMap('r1', {
        'category': 'erosion',
        'description': 'Bank collapsing near the trail',
        'county': 'Howard',
        'submitted_by': 'uid123',
        'status': 'active',
        'lat': 39.2,
        'lng': -76.8,
      });

      expect(report.category, ReportCategory.erosion);
      expect(report.title, 'Erosion Report');
      expect(report.categoryLabel, 'Bank collapsing near the trail');
      expect(report.isOfficial, isFalse);
      expect(report.locationApproximate, isFalse);
    });

    test('long descriptions get cut with an ellipsis', () {
      final report = CommunityReport.fromMap('r2', {
        'category': 'flooding',
        'description': 'A' * 100,
        'county': 'Howard',
      });
      expect(report.categoryLabel.length, 71);
      expect(report.categoryLabel.endsWith('…'), isTrue);
    });

    test('toCreateMap has what a submission needs', () {
      final report = CommunityReport(
        id: 'ignored-on-create',
        category: ReportCategory.illegalDumping,
        description: 'Trash dumped by the creek',
        county: 'Anne Arundel',
        date: DateTime(2026, 9, 1),
        mediaUrls: const ['https://example.com/photo.jpg'],
        locationLabel: 'Near the creek',
        submittedBy: 'uid456',
        status: ReportStatus.active,
        lat: 39.0,
        lng: -76.5,
        locationApproximate: true,
      );

      final map = report.toCreateMap();
      expect(map['category'], 'illegalDumping');
      expect(map['status'], 'active');
      expect(map['submitted_by'], 'uid456');
      expect(map['lat'], 39.0);
      expect(map['location_approximate'], isTrue);
      expect(map['media_urls'], ['https://example.com/photo.jpg']);
    });

    test('reads media_urls, or the old photo_url', () {
      final withMediaUrls = CommunityReport.fromMap('r3', {
        'category': 'other',
        'description': 'x',
        'county': 'Howard',
        'media_urls': [
          'https://example.com/a.jpg',
          'https://example.com/b.mp4',
        ],
      });
      expect(withMediaUrls.mediaUrls, [
        'https://example.com/a.jpg',
        'https://example.com/b.mp4',
      ]);
      expect(isVideoUrl(withMediaUrls.mediaUrls[1]), isTrue);
      expect(isVideoUrl(withMediaUrls.mediaUrls[0]), isFalse);

      final legacy = CommunityReport.fromMap('r4', {
        'category': 'other',
        'description': 'x',
        'county': 'Howard',
        'photo_url': 'https://example.com/legacy.jpg',
      });
      expect(legacy.mediaUrls, ['https://example.com/legacy.jpg']);
    });
  });

  group('EcoGuideMessage', () {
    test('stored map round trip', () {
      const message = EcoGuideMessage(
        role: EcoGuideRole.model,
        text: 'Erosion harms stream banks.',
      );
      final restored = EcoGuideMessage.fromStoredMap(message.toStoredMap());
      expect(restored.role, EcoGuideRole.model);
      expect(restored.text, 'Erosion harms stream banks.');
      expect(restored.isError, isFalse);
    });

    test('unknown role becomes user', () {
      final restored = EcoGuideMessage.fromStoredMap({'text': 'hi'});
      expect(restored.role, EcoGuideRole.user);
    });
  });

  group('EcoGuideChatThread.fromMap', () {
    test('reads the fields and last message', () {
      final thread = EcoGuideChatThread.fromMap({
        'item_type': 'report',
        'item_id': 'r1',
        'item_title': 'Erosion Report',
        'messages': [
          {'role': 'user', 'text': 'Why is this harmful?'},
          {'role': 'model', 'text': 'Erosion washes away soil...'},
        ],
        'updated_at': Timestamp.fromDate(DateTime(2026, 9, 23)),
      });

      expect(thread.itemType, 'report');
      expect(thread.isRecord, isFalse);
      expect(thread.itemTitle, 'Erosion Report');
      expect(thread.lastMessagePreview, 'Erosion washes away soil...');
      expect(thread.updatedAt, DateTime(2026, 9, 23));
    });

    test('handles an empty map', () {
      final thread = EcoGuideChatThread.fromMap({});
      expect(thread.itemType, 'report');
      expect(thread.isRecord, isFalse);
      expect(thread.itemTitle, 'Untitled');
      expect(thread.lastMessagePreview, '');
    });
  });
}
