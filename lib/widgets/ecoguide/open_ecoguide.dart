import 'package:flutter/material.dart';
import '../../main.dart' show mainScreenTabRequestNotifier;
import '../../models/environmental_item.dart';
import '../../screens/ecoguide_chat.dart';

// no item and no canned question - this is just "go to EcoGuide" and the
// persistent EcoGuide tab already covers that, so switch to it instead of
// pushing a second, disconnected chat on top
void openEcoGuide(
  BuildContext context, {
  EnvironmentalItem? item,
  String? question,
}) {
  if (item == null && question == null) {
    mainScreenTabRequestNotifier.value = 5;
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EcoGuideScreen(item: item, initialQuestion: question),
    ),
  );
}
