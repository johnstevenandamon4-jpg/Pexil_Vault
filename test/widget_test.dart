import 'package:flutter_test/flutter_test.dart';
import 'package:pexil_vault/main.dart';

void main() {
  group('PExil Vault App Tests', () {
    testWidgets('App launches successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const PExilVaultApp());

      expect(find.byType(PExilVaultApp), findsOneWidget);
    });
  });
}

