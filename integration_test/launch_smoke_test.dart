import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:realita62_life_board/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows the main menu', (tester) async {
    // Fresh state — no saved game, default settings.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const RealitaApp());
    // Allow the framework to pump at least one frame and let the
    // navigator settle.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The main menu must be visible: app title + a 'New Game' button.
    expect(find.text('Realita +62'), findsWidgets);
    expect(find.text('New Game'), findsWidgets);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
