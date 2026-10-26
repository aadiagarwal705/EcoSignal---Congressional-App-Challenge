import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart' show IconData;

typedef RecordPage = ({
  List<EnvironmentalItem> items,
  DocumentSnapshot? lastDocument,
  bool hasMore,
});

abstract class EnvironmentalItem {
  final String id;
  final String title;
  final String categoryLabel;
  final String county;
  final DateTime date;
  final double? lat;
  final double? lng;

  final bool isOfficial;

  const EnvironmentalItem({
    required this.id,
    required this.title,
    required this.categoryLabel,
    required this.county,
    required this.date,
    required this.lat,
    required this.lng,
    required this.isOfficial,
  });

  bool get hasLocation => lat != null && lng != null;

  IconData get icon;
}
