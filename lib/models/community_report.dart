import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'environmental_item.dart';

class CommunityReport extends EnvironmentalItem {
  final ReportCategory category;
  final String description;
  final List<String> mediaUrls;
  final String locationLabel;
  final String submittedBy;
  final ReportStatus status;

  final bool locationApproximate;

  CommunityReport({
    required super.id,
    required this.category,
    required this.description,
    required super.county,
    required super.date,
    required this.mediaUrls,
    required this.locationLabel,
    required this.submittedBy,
    required this.status,
    required super.lat,
    required super.lng,
    required this.locationApproximate,
  }) : super(
         title: '${category.label} Report',
         categoryLabel: description.length <= 70
             ? description
             : '${description.substring(0, 70).trimRight()}…',
         isOfficial: false,
       );

  factory CommunityReport.fromMap(String id, Map<String, dynamic> data) {
    final rawMediaUrls = data['media_urls'] as List<dynamic>?;
    final legacyPhotoUrl = data['photo_url'] as String?;
    return CommunityReport(
      id: id,
      category: ReportCategory.fromDb(data['category'] as String?),
      description: data['description'] ?? '',
      county: data['county'] ?? 'Unknown',
      date: (data['submitted_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrls: rawMediaUrls != null
          ? rawMediaUrls.cast<String>()
          : (legacyPhotoUrl != null ? [legacyPhotoUrl] : const []),
      locationLabel: data['location_label'] ?? '',
      submittedBy: data['submitted_by'] ?? '',
      status: ReportStatus.fromDb(data['status'] as String?),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      locationApproximate: data['location_approximate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'category': category.dbValue,
    'description': description,
    'county': county,
    'submitted_at': FieldValue.serverTimestamp(),
    'media_urls': mediaUrls,
    'location_label': locationLabel,
    'submitted_by': submittedBy,
    'status': status.dbValue,
    'lat': lat,
    'lng': lng,
    'location_approximate': locationApproximate,
  };

  @override
  IconData get icon => category.icon;
}

bool isVideoUrl(String url) {
  final path = Uri.parse(url).path.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.m4v');
}
