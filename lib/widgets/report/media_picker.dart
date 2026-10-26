import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import '../../constants/app_theme.dart';

class PickedMedia {
  final File file;
  final bool isVideo;
  const PickedMedia({required this.file, required this.isVideo});
}

class MediaPickerField extends StatelessWidget {
  static const maxPhotos = 5;
  static const maxVideos = 1;
  static const maxVideoBytes = 75 * 1024 * 1024;

  final List<PickedMedia> media;
  final ValueChanged<List<PickedMedia>> onChanged;

  const MediaPickerField({
    super.key,
    required this.media,
    required this.onChanged,
  });

  int get _photoCount => media.where((m) => !m.isVideo).length;
  int get _videoCount => media.where((m) => m.isVideo).length;

  Future<void> _addPhoto(BuildContext context) async {
    final remaining = maxPhotos - _photoCount;
    final source = await _pickSource(
      context,
      video: false,
      galleryLimit: remaining,
    );
    if (source == null) return;
    try {
      final List<XFile> picked;
      if (source == ImageSource.camera) {
        final shot = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1600,
          imageQuality: 75,
        );
        picked = shot == null ? [] : [shot];
      } else {
        picked = await ImagePicker().pickMultiImage(
          maxWidth: 1600,
          imageQuality: 75,
          limit: remaining,
        );
      }
      final added = picked
          .take(remaining)
          .map((x) => PickedMedia(file: File(x.path), isVideo: false))
          .toList();
      if (added.isNotEmpty) onChanged([...media, ...added]);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _addVideo(BuildContext context) async {
    final source = await _pickSource(context, video: true);
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null) return;
      if (!context.mounted) return;
      final file = await _shrinkVideo(context, File(picked.path));
      final size = await file.length();
      if (size >= maxVideoBytes) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'That video is too large. Videos must be under 75 MB — try a shorter clip.',
              ),
            ),
          );
        }
        return;
      }
      onChanged([...media, PickedMedia(file: file, isVideo: true)]);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<File> _shrinkVideo(BuildContext context, File original) async {
    final before = await original.length();
    if (!context.mounted) return original;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Preparing video…')),
            ],
          ),
        ),
      ),
    );
    try {
      final info = await VideoCompress.compressVideo(
        original.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      final outPath = info?.path;
      if (outPath == null) return original;
      final compressed = File(outPath);
      final after = await compressed.length();
      return after < before ? compressed : original;
    } catch (_) {
      return original;
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open the camera/gallery: $e')),
    );
  }

  Future<ImageSource?> _pickSource(
    BuildContext context, {
    required bool video,
    int? galleryLimit,
  }) {
    final multi = !video && galleryLimit != null && galleryLimit > 1;
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.spaceSmall),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(video ? 'Record Video' : 'Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                multi
                    ? 'Choose from Gallery (up to $galleryLimit)'
                    : 'Choose from Gallery',
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _remove(int index) {
    final next = [...media]..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTheme.spaceSmall,
          runSpacing: AppTheme.spaceSmall,
          children: [
            for (int i = 0; i < media.length; i++)
              _MediaThumb(media: media[i], onRemove: () => _remove(i)),
            if (_photoCount < maxPhotos)
              _AddTile(
                icon: Icons.add_a_photo_outlined,
                label: 'Photo',
                onTap: () => _addPhoto(context),
              ),
            if (_videoCount < maxVideos)
              _AddTile(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: () => _addVideo(context),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Up to $maxPhotos photos and $maxVideos video',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textTertiaryOf(context),
          ),
        ),
      ],
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final PickedMedia media;
  final VoidCallback onRemove;

  const _MediaThumb({required this.media, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: media.isVideo
              ? Container(
                  width: 90,
                  height: 90,
                  color: Colors.black87,
                  child: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                )
              : Image.file(
                  media.file,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: Icon(Icons.close_rounded, size: 14, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.textTertiaryOf(context).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppTheme.textSecondaryOf(context)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
