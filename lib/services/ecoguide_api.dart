import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/chat_message.dart';

class EcoGuideService {
  final _functions = FirebaseFunctions.instance;

  Future<String> ask({
    required String question,
    String? itemType,
    String? itemId,
    List<EcoGuideMessage> history = const [],
    File? image,
  }) async {
    try {
      final callable = _functions.httpsCallable('askEcoGuide');
      final result = await callable.call<Map<String, dynamic>>({
        'question': question,
        'itemType': ?itemType,
        'itemId': ?itemId,
        if (history.isNotEmpty)
          'history': history.map((m) => m.toHistoryEntry()).toList(),
        if (image != null) 'imageBase64': base64Encode(await image.readAsBytes()),
        if (image != null) 'mimeType': 'image/jpeg',
      });
      final reply = result.data['reply'] as String?;
      if (reply == null || reply.isEmpty) {
        throw Exception('EcoGuide sent back an empty reply.');
      }
      return reply;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? "EcoGuide couldn't answer that just now.");
    }
  }
}
