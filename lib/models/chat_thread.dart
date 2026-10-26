import 'package:cloud_firestore/cloud_firestore.dart';

class EcoGuideChatThread {
  final String itemType;
  final String itemId;
  final String itemTitle;
  final String lastMessagePreview;
  final String? lastImageUrl;
  final DateTime updatedAt;

  const EcoGuideChatThread({
    required this.itemType,
    required this.itemId,
    required this.itemTitle,
    required this.lastMessagePreview,
    this.lastImageUrl,
    required this.updatedAt,
  });

  bool get isRecord => itemType == 'record';
  bool get isGeneral => itemType == 'general';

  factory EcoGuideChatThread.fromMap(Map<String, dynamic> data) {
    final messages = (data['messages'] as List<dynamic>? ?? const []);
    final lastMap = messages.isEmpty
        ? const <String, dynamic>{}
        : messages.last as Map<String, dynamic>;
    return EcoGuideChatThread(
      itemType: data['item_type'] as String? ?? 'report',
      itemId: data['item_id'] as String? ?? '',
      itemTitle: data['item_title'] as String? ?? 'Untitled',
      lastMessagePreview: lastMap['text'] as String? ?? '',
      lastImageUrl: lastMap['image_url'] as String?,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
