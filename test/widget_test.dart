import 'package:ecosignal_project/widgets/common/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState shows text and button', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.eco_outlined,
            title: 'Nothing here',
            message: 'Come back later.',
            actionLabel: 'Explore',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Come back later.'), findsOneWidget);
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);

    await tester.tap(find.text('Explore'));
    expect(tapped, isTrue);
  });

  testWidgets('EmptyState has no button without an action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results',
            message: 'Try again.',
          ),
        ),
      ),
    );

    expect(find.byType(ElevatedButton), findsNothing);
  });
}
