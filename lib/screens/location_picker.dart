import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_theme.dart';
import '../services/geo.dart';
import '../utils/snackbar.dart';

typedef PickedLocation = ({
  double lat,
  double lng,
  String label,
  String? county,
});

const _defaultCenter = LatLng(39.15, -76.85);
const _defaultZoom = 9.5;

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const LocationPickerScreen({super.key, this.initialCenter});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _geoService = GeoService();
  final _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng _center = _defaultCenter;

  bool _locating = false;
  bool _searching = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) _center = widget.initialCenter!;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final position = await _geoService.getDevicePosition();
    if (!mounted) return;
    setState(() => _locating = false);
    if (position == null) {
      showAppSnackBar(
        context,
        "Couldn't get your location — check Location Services is on.",
        type: SnackType.error,
      );
      return;
    }
    _center = position;
    _mapController.move(position, 16);
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    final result = await _geoService.searchAddress(query);
    if (!mounted) return;
    setState(() => _searching = false);
    if (result == null) {
      showAppSnackBar(
        context,
        'No results for "$query"',
        type: SnackType.error,
      );
      return;
    }
    _center = result;
    _mapController.move(result, 15);
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    final description = await _geoService.describeLocation(_center);
    if (!mounted) return;
    Navigator.pop<PickedLocation>(context, (
      lat: _center.latitude,
      lng: _center.longitude,
      label: description.label,
      county: description.county,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initialCenter != null ? 13 : _defaultZoom,
              minZoom: 6,
              maxZoom: 18,
              onPositionChanged: (camera, hasGesture) =>
                  _center = camera.center,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecosignal.md',
              ),
            ],
          ),

          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Icon(
                  Icons.location_pin,
                  size: 44,
                  color: AppTheme.communityBadge,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: AppTheme.spaceMedium,
            right: AppTheme.spaceMedium,
            top: AppTheme.spaceMedium,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Search city, address, or landmark',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded),
                          onPressed: _search,
                        ),
                  filled: true,
                  fillColor: AppTheme.surfaceOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: AppTheme.spaceMedium,
            bottom: 100,
            child: FloatingActionButton.small(
              heroTag: 'use-current-location',
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          Positioned(
            left: AppTheme.spaceMedium,
            right: AppTheme.spaceMedium,
            bottom: AppTheme.spaceMedium,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _confirming ? null : _confirm,
                  icon: _confirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Use This Location'),
                  style: AppTheme.primaryButtonOf(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
