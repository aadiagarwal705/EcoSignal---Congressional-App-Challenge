import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/community_event.dart';
import '../models/environmental_item.dart';
import '../services/events.dart';
import '../utils/formatters.dart';
import '../utils/snackbar.dart';
import '../widgets/report/location_field.dart';
import 'event_detail.dart';
import 'location_picker.dart';
import 'report_picker.dart';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  EnvironmentalItem? _linkedItem;
  DateTime? _dateTime;
  LatLng? _pickedLocation;
  String? _pickedLabel;
  String? _county;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _titleController.text.trim().isNotEmpty &&
      _dateTime != null &&
      _dateTime!.isAfter(DateTime.now()) &&
      _pickedLocation != null &&
      _county != null;

  Future<void> _pickReport() async {
    final picked = await Navigator.push<EnvironmentalItem>(
      context,
      MaterialPageRoute(builder: (_) => const ReportPickerScreen()),
    );
    if (picked != null) setState(() => _linkedItem = picked);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _dateTime != null ? TimeOfDay.fromDateTime(_dateTime!) : const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result == null) return;
    setState(() {
      _pickedLocation = LatLng(result.lat, result.lng);
      _pickedLabel = result.label;
      if (result.county != null) _county = result.county;
    });
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_canSubmit) return;

    setState(() => _submitting = true);
    final service = EventService();
    final id = service.newEventId();
    final event = CommunityEvent(
      id: id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      organizerUid: user.uid,
      organizerName: user.displayName ?? user.email ?? 'A community member',
      dateTime: _dateTime!,
      locationLabel: _pickedLabel ?? _county!,
      county: _county!,
      lat: _pickedLocation!.latitude,
      lng: _pickedLocation!.longitude,
      reportId: _linkedItem?.id,
      reportLabel: _linkedItem == null
          ? null
          : (_linkedItem!.isOfficial ? _linkedItem!.title : _linkedItem!.categoryLabel),
      linkedItemType: _linkedItem?.isOfficial == true ? 'record' : 'report',
      attendeeUids: const [],
      createdAt: DateTime.now(),
      status: EventStatus.active,
    );

    try {
      await service.submitEvent(id, event);
      if (!mounted) return;
      showAppSnackBar(context, 'Event posted to the bulletin board!', type: SnackType.success);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
        result: true,
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not post the event: $e', type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organize an Event')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        children: [
          Text(
            'Gather people to clean up or help with a local issue',
            style: AppTheme.subtitle.copyWith(color: AppTheme.textSecondaryOf(context)),
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          Text('Link a report (optional)', style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 8),
          if (_linkedItem == null)
            OutlinedButton.icon(
              onPressed: _pickReport,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Choose a report or record'),
            )
          else
            Builder(
              builder: (context) {
                final item = _linkedItem!;
                final badgeColor = item.isOfficial ? AppTheme.officialBadge : AppTheme.communityBadge;
                return Container(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, color: badgeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.isOfficial ? item.title : item.categoryLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body.copyWith(color: AppTheme.textPrimaryOf(context)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _linkedItem = null),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: AppTheme.spaceLarge),

          Text('Event Title', style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            maxLength: 100,
            decoration: const InputDecoration(hintText: 'e.g. Patapsco Creek Cleanup'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          Text('Details (optional)', style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'What should people bring or expect?'),
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          Text('Date & Time', style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDateTime,
            icon: const Icon(Icons.event_outlined),
            label: Text(_dateTime == null ? 'Choose date and time' : formatEventWhen(_dateTime!)),
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          Text('Location', style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 8),
          LocationField(label: _pickedLabel, onTap: _pickLocation),
          const SizedBox(height: AppTheme.spaceLarge),

          Text('County', style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 8),
          Wrap(
            spacing: AppTheme.spaceSmall,
            runSpacing: AppTheme.spaceSmall,
            children: [
              for (final county in AppConstants.scopedCounties)
                ChoiceChip(
                  label: Text(county),
                  selected: _county == county,
                  onSelected: (_) => setState(() => _county = county),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXLarge),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: AppTheme.primaryButtonOf(context),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post to the Bulletin Board'),
            ),
          ),
        ],
      ),
    );
  }
}
