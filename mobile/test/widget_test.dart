// cSpell:ignore Cropsify
import 'package:flutter_test/flutter_test.dart';
import 'package:cropsify/main.dart';

void main() {
  testWidgets('CropsifyApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const CropsifyApp());
    expect(find.byType(CropsifyApp), findsOneWidget);
  });
}