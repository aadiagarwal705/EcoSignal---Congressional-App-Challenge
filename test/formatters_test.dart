import 'package:ecosignal_project/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDate', () {
    expect(formatDate(DateTime(2026, 9, 18)), 'Sep 18, 2026');
    expect(formatDate(DateTime(2026, 1, 5)), 'Jan 5, 2026');
  });
}
