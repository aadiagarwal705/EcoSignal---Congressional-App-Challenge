import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

typedef UploadProgress = void Function(int bytesTransferred, int totalBytes);

class UploadCancelledException implements Exception {
  const UploadCancelledException();

  @override
  String toString() => 'Upload cancelled';
}

class UploadCancelToken {
  final List<UploadTask> _tasks = [];
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    for (final task in List.of(_tasks)) {
      task.cancel();
    }
  }
}

class StorageService {
  final _storage = FirebaseStorage.instance;

  static const _probeAfter = Duration(seconds: 20);
  static const _giveUpAfter = Duration(minutes: 10);

  // pings storage directly - this is how we tell "just slow" from "actually offline"
  Future<bool> _reachable() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final request = await client
          .headUrl(Uri.parse('https://firebasestorage.googleapis.com/'))
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      await response.drain<void>();
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  // Took a few tries to get this watchdog right - don't touch it without testing on a
  // flaky connection. Silence for 20s triggers a reachability check, and we only tell the
  // user we're "reconnecting" if that check actually fails. 10 minutes of nothing = give up.
  Future<String> uploadReportMedia({
    required String uid,
    required String reportId,
    required File file,
    required int index,
    required bool isVideo,
    UploadProgress? onProgress,
    ValueChanged<bool>? onReconnecting,
    UploadCancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      throw const UploadCancelledException();
    }

    final ext = isVideo ? 'mp4' : 'jpg';
    final contentType = isVideo ? 'video/mp4' : 'image/jpeg';
    final ref = _storage.ref(
      'community_reports/$uid/$reportId/media_$index.$ext',
    );

    final task = ref.putFile(file, SettableMetadata(contentType: contentType));
    cancelToken?._tasks.add(task);
    var lastEvent = DateTime.now();
    var reconnecting = false;

    final sub = task.snapshotEvents.listen((s) {
      lastEvent = DateTime.now();
      if (reconnecting) {
        reconnecting = false;
        onReconnecting?.call(false);
      }
      onProgress?.call(s.bytesTransferred, s.totalBytes);
    });

    var finished = false;
    var probing = false;
    final watchdog = Timer.periodic(const Duration(seconds: 3), (_) async {
      final silent = DateTime.now().difference(lastEvent);
      if (silent > _giveUpAfter) {
        task.cancel();
        return;
      }
      if (silent < _probeAfter || probing) return;

      probing = true;
      final online = await _reachable();
      probing = false;
      if (finished) return;

      if (!online && !reconnecting) {
        reconnecting = true;
        onReconnecting?.call(true);
      } else if (online && reconnecting) {
        reconnecting = false;
        onReconnecting?.call(false);
      }
    });

    try {
      await task;
    } on FirebaseException catch (e) {
      if (cancelToken?.isCancelled ?? false) {
        throw const UploadCancelledException();
      }
      if (e.code == 'canceled') {
        throw Exception(
          'Could not reach the server. Check your connection and try again.',
        );
      }
      rethrow;
    } finally {
      finished = true;
      watchdog.cancel();
      await sub.cancel();
      cancelToken?._tasks.remove(task);
      if (reconnecting) onReconnecting?.call(false);
    }

    return ref.getDownloadURL();
  }

  Future<String> uploadChatImage({
    required String uid,
    required String threadId,
    required File file,
  }) async {
    final ref = _storage.ref(
      'ecoguide_chats/$uid/$threadId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> deleteReportMedia({
    required String uid,
    required String reportId,
    required List<bool> isVideoByIndex,
  }) async {
    await Future.wait([
      for (int i = 0; i < isVideoByIndex.length; i++)
        _storage
            .ref(
              'community_reports/$uid/$reportId/media_$i.${isVideoByIndex[i] ? 'mp4' : 'jpg'}',
            )
            .delete()
            .catchError((_) {}),
    ]);
  }
}
