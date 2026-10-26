import 'dart:io';

enum EcoGuideRole { user, model }

class EcoGuideMessage {
  final EcoGuideRole role;
  final String text;
  final bool isError;

  // imageUrl is the persisted Storage download URL (survives app restarts).
  // localImage is only ever set for an image this session just sent/loaded - never stored.
  final String? imageUrl;
  final File? localImage;

  const EcoGuideMessage({
    required this.role,
    required this.text,
    this.isError = false,
    this.imageUrl,
    this.localImage,
  });

  Map<String, String> toHistoryEntry() => {
    'role': role == EcoGuideRole.model ? 'model' : 'user',
    'text': text,
  };

  Map<String, dynamic> toStoredMap() => {
    'role': role == EcoGuideRole.model ? 'model' : 'user',
    'text': text,
    if (imageUrl != null) 'image_url': imageUrl,
  };

  factory EcoGuideMessage.fromStoredMap(Map<String, dynamic> map) =>
      EcoGuideMessage(
        role: map['role'] == 'model' ? EcoGuideRole.model : EcoGuideRole.user,
        text: map['text'] as String? ?? '',
        imageUrl: map['image_url'] as String?,
      );
}
