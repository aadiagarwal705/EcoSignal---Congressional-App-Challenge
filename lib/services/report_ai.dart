import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import '../constants/app_constants.dart';

typedef ReportSuggestion = ({ReportCategory category, String description});

class ReportAiService {
  final _functions = FirebaseFunctions.instance;

  Future<ReportSuggestion> suggestDetails(File photo) async {
    try {
      final bytes = await photo.readAsBytes();
      final callable = _functions.httpsCallable('suggestReportDetails');
      final result = await callable.call<Map<String, dynamic>>({
        'imageBase64': base64Encode(bytes),
        'mimeType': 'image/jpeg',
      });
      return (
        category: ReportCategory.fromDb(result.data['category'] as String?),
        description: result.data['description'] as String? ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      // anything other than the rate-limit message is unreliable to show as-is -
      // a platform-level timeout, for instance, comes back with message == "INTERNAL"
      if (e.code == 'resource-exhausted' && e.message != null) {
        throw Exception(e.message);
      }
      throw Exception("Couldn't look at that photo just now — please try again.");
    }
  }
}
