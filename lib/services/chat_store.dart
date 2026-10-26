import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';

class EcoGuideChatService {
  final _firestore = FirebaseFirestore.instance;

  String threadId(String itemType, String itemId) => '${itemType}_$itemId';

  CollectionReference<Map<String, dynamic>>? _threads() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('user_preferences')
        .doc(uid)
        .collection('ecoguide_chats');
  }

  Future<List<EcoGuideMessage>> loadThread(
    String itemType,
    String itemId,
  ) async {
    final threads = _threads();
    if (threads == null) return [];
    try {
      final doc = await threads.doc(threadId(itemType, itemId)).get();
      final messages = doc.data()?['messages'] as List<dynamic>?;
      if (messages == null) return [];
      return messages
          .map((m) => EcoGuideMessage.fromStoredMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveThread({
    required String itemType,
    required String itemId,
    required String itemTitle,
    required List<EcoGuideMessage> messages,
  }) async {
    final threads = _threads();
    if (threads == null || messages.isEmpty) return;
    try {
      await threads.doc(threadId(itemType, itemId)).set({
        'item_type': itemType,
        'item_id': itemId,
        'item_title': itemTitle,
        'messages': messages.map((m) => m.toStoredMap()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<List<EcoGuideChatThread>> get myThreadsStream {
    final threads = _threads();
    if (threads == null) return Stream.value(const []);
    return threads
        .orderBy('updated_at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => EcoGuideChatThread.fromMap(d.data()))
              .toList(),
        );
  }
}
