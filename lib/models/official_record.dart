import 'package:flutter/material.dart';
import 'environmental_item.dart';

class OfficialRecord extends EnvironmentalItem {
  final String siteName;
  final String address;
  final String cityStateZip;
  final String inspectionType;
  final String inspectionReason;
  final String siteStatus;
  final String siteCondition;
  final String recommendedActions;
  final String permitNo;
  final String npdesNo;

  final String sourceUrl;

  final bool locationApproximate;

  const OfficialRecord({
    required super.id,
    required this.siteName,
    required this.address,
    required this.cityStateZip,
    required super.county,
    required this.inspectionType,
    required this.inspectionReason,
    required super.date,
    required this.siteStatus,
    required this.siteCondition,
    required this.recommendedActions,
    required this.permitNo,
    required this.npdesNo,
    required this.sourceUrl,
    required super.lat,
    required super.lng,
    required this.locationApproximate,
  }) : super(title: siteName, categoryLabel: inspectionType, isOfficial: true);

  factory OfficialRecord.fromMap(String id, Map<String, dynamic> data) {
    return OfficialRecord(
      id: id,
      siteName: data['site_name'] ?? 'Unnamed site',
      address: data['address'] ?? '',
      cityStateZip: _spaceOutCommas(data['city_state_zip'] ?? ''),
      county: data['county'] ?? 'Unknown',
      inspectionType: _humanize(data['inspection_type'] ?? 'Inspection'),
      inspectionReason: data['inspection_reason'] ?? '',
      date: data['inspection_date']?.toDate() ?? DateTime.now(),
      siteStatus: data['site_status'] ?? 'Not Evaluated',
      siteCondition: data['site_condition'] ?? '',
      recommendedActions: data['recommended_actions'] ?? '',
      permitNo: data['permit_no'] ?? 'N/A',
      npdesNo: data['npdes_no'] ?? 'N/A',
      sourceUrl: data['source_url'] ?? '',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      locationApproximate: data['location_approximate'] as bool? ?? false,
    );
  }

  @override
  IconData get icon {
    final t = inspectionType.toLowerCase();
    if (t.contains('erosion')) return Icons.terrain_rounded;
    if (t.contains('wetland')) return Icons.grass_rounded;
    if (t.contains('dumping')) return Icons.delete_outline_rounded;
    if (t.contains('waterway') || t.contains('water') || t.contains('npdes')) {
      return Icons.water_drop_outlined;
    }
    return Icons.description_rounded;
  }
}

String _humanize(String value) =>
    value.replaceAll(RegExp(r'[_-]+'), ' ').trim();

String _spaceOutCommas(String value) =>
    value.replaceAll(RegExp(r',(?=\S)'), ', ');
