import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';

class GeoService {
  Geocoding? _geocodingInstance;

  // no web implementation for this plugin - it throws just from being constructed there
  Geocoding? get _geocoding {
    if (kIsWeb) return null;
    try {
      return _geocodingInstance ??= Geocoding();
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> getDevicePosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> searchAddress(String query) async {
    final geocoding = _geocoding;
    if (geocoding == null) return null;
    try {
      final results = await geocoding.locationFromAddress('$query, Maryland');
      if (results.isEmpty) return null;
      return LatLng(results.first.latitude, results.first.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<({String label, String? county})> describeLocation(
    LatLng point,
  ) async {
    final geocoding = _geocoding;
    if (geocoding == null) {
      return (label: _coordinateLabel(point), county: null);
    }
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) {
        return (label: _coordinateLabel(point), county: null);
      }

      final p = placemarks.first;
      final label = [
        p.locality,
        p.subAdministrativeArea,
      ].where((s) => s != null && s.isNotEmpty).join(', ');
      return (
        label: label.isNotEmpty ? label : _coordinateLabel(point),
        county: _matchScopedCounty(p.subAdministrativeArea),
      );
    } catch (_) {
      return (label: _coordinateLabel(point), county: null);
    }
  }

  String _coordinateLabel(LatLng point) =>
      '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';

  String? _matchScopedCounty(String? subAdministrativeArea) {
    if (subAdministrativeArea == null) return null;
    final normalized = subAdministrativeArea
        .replaceAll('County', '')
        .trim()
        .toLowerCase();
    for (final county in AppConstants.scopedCounties) {
      if (county.toLowerCase() == normalized) return county;
    }
    return null;
  }
}
