import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../main.dart' show authNotifier, mainScreenTabRequestNotifier;
import '../models/community_report.dart';
import '../services/auth.dart';
import '../services/report_ai.dart';
import '../services/reports.dart';
import '../services/uploads.dart';
import '../utils/snackbar.dart';
import '../widgets/ecoguide/open_ecoguide.dart';
import '../widgets/report/ask_ecoguide_sheet.dart';
import '../widgets/report/category_picker.dart';
import '../widgets/report/location_field.dart';
import '../widgets/report/media_picker.dart';
import '../widgets/report/sign_in_prompt.dart';
import '../widgets/report/upload_progress.dart';
import 'location_picker.dart';
import 'report_detail.dart';

class ReportIssueScreen extends StatelessWidget {
  final File? initialPhoto;

  const ReportIssueScreen({super.key, this.initialPhoto});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: authNotifier,
      builder: (context, user, _) {
        return AuthService.isGuest(user)
            ? const SignInPrompt()
            : _ReportForm(initialPhoto: initialPhoto);
      },
    );
  }
}

class _ReportForm extends StatefulWidget {
  final File? initialPhoto;

  const _ReportForm({this.initialPhoto});

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _descriptionController = TextEditingController();
  final _locationDetailController = TextEditingController();

  List<PickedMedia> _media = [];
  ReportCategory? _category;
  String? _county;
  LatLng? _pickedLocation;
  String? _pickedLabel;
  bool _submitting = false;
  bool _saving = false;
  bool _suggesting = false;
  List<int> _sentBytes = [];
  int _totalBytes = 0;
  int _filesDone = 0;
  UploadCancelToken? _cancelToken;
  final Set<int> _reconnectingFiles = {};

  @override
  void initState() {
    super.initState();
    final photo = widget.initialPhoto;
    if (photo != null) _media = [PickedMedia(file: photo, isVideo: false)];
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _descriptionController.dispose();
    _locationDetailController.dispose();
    super.dispose();
  }

  bool get _hasDraft =>
      _media.isNotEmpty ||
      _category != null ||
      _pickedLocation != null ||
      _descriptionController.text.trim().isNotEmpty ||
      _locationDetailController.text.trim().isNotEmpty;

  void _clearForm() {
    setState(() {
      _media = [];
      _category = null;
      _county = null;
      _pickedLocation = null;
      _pickedLabel = null;
      _descriptionController.clear();
      _locationDetailController.clear();
    });
  }

  Future<void> _discardDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this report?'),
        content: const Text(
          'Everything you entered, including photos and video, will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _clearForm();
    mainScreenTabRequestNotifier.value = 0;
  }

  PickedMedia? get _firstPhoto =>
      _media.where((m) => !m.isVideo).firstOrNull;

  bool get _hasBlankFields =>
      _category == null || _descriptionController.text.trim().isEmpty;

  bool get _canSuggest => !_suggesting && _firstPhoto != null && _hasBlankFields;

  Future<void> _suggestWithAi() async {
    final photo = _firstPhoto;
    if (photo == null) return;
    setState(() => _suggesting = true);
    try {
      final suggestion = await ReportAiService().suggestDetails(photo.file);
      if (!mounted) return;
      setState(() {
        _category ??= suggestion.category;
        if (_descriptionController.text.trim().isEmpty) {
          _descriptionController.text = suggestion.description;
        }
      });
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, '$e', type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  bool get _canSubmit =>
      !_submitting &&
      _media.isNotEmpty &&
      _category != null &&
      _county != null &&
      _pickedLocation != null &&
      _descriptionController.text.trim().isNotEmpty;

  Future<void> _openLocationPicker() async {
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

  // uploads everything first, then saves the report doc. if it fails or gets
  // cancelled partway we clean up whatever already made it to storage
  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_canSubmit) return;

    final token = UploadCancelToken();
    final kinds = _media.map((m) => m.isVideo).toList();
    final reportService = ReportService();
    final reportId = reportService.newReportId();

    setState(() {
      _submitting = true;
      _cancelToken = token;
      _reconnectingFiles.clear();
    });
    try {
      final sizes = await Future.wait(_media.map((m) => m.file.length()));
      setState(() {
        _sentBytes = List.filled(_media.length, 0);
        _totalBytes = sizes.fold(0, (a, b) => a + b);
        _filesDone = 0;
        _saving = false;
      });

      final storage = StorageService();
      // photos go first and the video last, since it is the biggest
      final order = [
        for (int i = 0; i < _media.length; i++)
          if (!_media[i].isVideo) i,
        for (int i = 0; i < _media.length; i++)
          if (_media[i].isVideo) i,
      ];
      final mediaUrls = await _runLimited<String>(order, 2, (i) async {
        final url = await storage.uploadReportMedia(
          uid: user.uid,
          reportId: reportId,
          file: _media[i].file,
          index: i,
          isVideo: _media[i].isVideo,
          cancelToken: token,
          onProgress: (sent, _) {
            if (mounted) {
              setState(() {
                _sentBytes[i] = sent;
              });
            }
          },
          onReconnecting: (isReconnecting) {
            if (mounted) {
              setState(() {
                if (isReconnecting) {
                  _reconnectingFiles.add(i);
                } else {
                  _reconnectingFiles.remove(i);
                }
              });
            }
          },
        );
        if (mounted) {
          setState(() {
            _filesDone++;
          });
        }
        return url;
      });
      if (mounted) {
        setState(() {
          _saving = true;
        });
      }

      final report = CommunityReport(
        id: reportId,
        category: _category!,
        description: _descriptionController.text.trim(),
        county: _county!,
        date: DateTime.now(),
        mediaUrls: mediaUrls,
        locationLabel: _locationDetailController.text.trim().isNotEmpty
            ? _locationDetailController.text.trim()
            : (_pickedLabel ?? _county!),
        submittedBy: user.uid,
        status: ReportStatus.active,
        lat: _pickedLocation!.latitude,
        lng: _pickedLocation!.longitude,
        locationApproximate: false,
      );

      await reportService.submitReport(reportId, report);
      if (!mounted) return;

      _clearForm();
      setState(() {
        _submitting = false;
        _saving = false;
      });
      showAppSnackBar(
        context,
        'Report submitted — thank you!',
        type: SnackType.success,
      );
      final askNow = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AskEcoGuideSheet(),
      );
      if (!mounted) return;
      if (askNow == true) {
        openEcoGuide(
          context,
          item: report,
          question:
              "I just reported this issue and I'm at the location right now. What can I safely do right now, "
              'on the spot, and who should I contact?',
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailScreen(report: report)),
        );
      }
    } on UploadCancelledException {
      await StorageService().deleteReportMedia(
        uid: user.uid,
        reportId: reportId,
        isVideoByIndex: kinds,
      );
      if (mounted) {
        showAppSnackBar(context, 'Upload cancelled', type: SnackType.info);
      }
    } catch (e) {
      await StorageService().deleteReportMedia(
        uid: user.uid,
        reportId: reportId,
        isVideoByIndex: kinds,
      );
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not submit the report: $e',
          type: SnackType.error,
        );
      }
    } finally {
      _cancelToken = null;
      if (mounted) {
        setState(() {
          _submitting = false;
          _saving = false;
          _reconnectingFiles.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      children: [
        MediaPickerField(
          media: _media,
          onChanged: (m) => setState(() => _media = m),
        ),
        if (_firstPhoto != null && (_hasBlankFields || _suggesting)) ...[
          const SizedBox(height: AppTheme.spaceSmall),
          OutlinedButton.icon(
            onPressed: _canSuggest ? _suggestWithAi : null,
            icon: _suggesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              _suggesting ? 'Looking at your photo...' : 'Suggest Category & Description with AI',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ai,
              side: const BorderSide(color: AppTheme.ai),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spaceLarge),

        Text(
          'Issue Category',
          style: AppTheme.bodyBold.copyWith(
            color: AppTheme.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        CategoryPicker(
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: AppTheme.spaceLarge),

        Text(
          'Location',
          style: AppTheme.bodyBold.copyWith(
            color: AppTheme.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        LocationField(label: _pickedLabel, onTap: _openLocationPicker),
        const SizedBox(height: AppTheme.spaceLarge),

        Text(
          'County',
          style: AppTheme.bodyBold.copyWith(
            color: AppTheme.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
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
        const SizedBox(height: AppTheme.spaceLarge),

        Text(
          'Location Details (optional)',
          style: AppTheme.bodyBold.copyWith(
            color: AppTheme.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        TextField(
          controller: _locationDetailController,
          decoration: const InputDecoration(
            hintText: 'e.g. Near the bridge on Route 40',
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),

        Row(
          children: [
            Text(
              'Short Description',
              style: AppTheme.bodyBold.copyWith(
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _descriptionController,
              builder: (context, _) => Text(
                '${_descriptionController.text.length}/500',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textTertiaryOf(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          decoration: const InputDecoration(
            hintText:
                'Describe what you saw, when it happened, and any other relevant details...',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppTheme.spaceLarge),

        if (_submitting) ...[
          UploadProgressBar(
            sent: _sentBytes.fold(0, (a, b) => a + b),
            total: _totalBytes,
            done: _filesDone,
            count: _media.length,
            saving: _saving,
            reconnecting: _reconnectingFiles.isNotEmpty,
            onCancel: () => _cancelToken?.cancel(),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            style: AppTheme.primaryButtonOf(context),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Report'),
          ),
        ),
        if (!_submitting && _hasDraft)
          Center(
            child: TextButton(
              onPressed: _discardDraft,
              child: Text(
                'Discard report',
                style: TextStyle(color: AppTheme.textSecondaryOf(context)),
              ),
            ),
          ),
        const SizedBox(height: AppTheme.spaceSmall),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: AppTheme.textTertiaryOf(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Community reports are separate from official state records.',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textTertiaryOf(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLarge),
      ],
    );
  }
}

// runs the jobs a couple at a time instead of all at once so they do not fight over one connection.
// stops picking up new jobs as soon as one fails.
Future<List<T>> _runLimited<T>(
  List<int> order,
  int limit,
  Future<T> Function(int index) job,
) async {
  final results = List<T?>.filled(order.length, null);
  var next = 0;
  var failed = false;

  Future<void> worker() async {
    while (!failed && next < order.length) {
      final index = order[next++];
      try {
        results[index] = await job(index);
      } catch (_) {
        failed = true;
        rethrow;
      }
    }
  }

  await Future.wait(
    List.generate(limit < order.length ? limit : order.length, (_) => worker()),
  );
  return results.cast<T>();
}
