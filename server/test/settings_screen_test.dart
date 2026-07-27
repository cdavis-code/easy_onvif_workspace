import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_onvif_server/src/settings.dart';
import 'package:easy_onvif_server/src/settings_store.dart';
import 'package:easy_onvif_server/src/ui/settings_screen.dart';

void main() {
  late Directory tempDir;
  late SettingsStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('settings_screen_test');
    store = SettingsStore(directoryOverride: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  /// Pumps a host page whose button pushes the settings screen, so the test
  /// can observe the popped result like the real caller does.
  Future<ServerSettings? Function()> openScreen(
    WidgetTester tester,
    ServerSettings settings,
  ) async {
    ServerSettings? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<ServerSettings>(
                    MaterialPageRoute(
                      builder: (_) =>
                          SettingsScreen(settings: settings, store: store),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return () => result;
  }

  testWidgets('editing fields and saving returns the updated settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final getResult = await openScreen(tester, const ServerSettings());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Manufacturer'),
      'Acme',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'HTTP port'),
      '9080',
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Audio streaming'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final result = getResult();

    expect(result, isNotNull);
    expect(result!.config.manufacturer, 'Acme');
    expect(result.config.httpPort, 9080);
    expect(result.media.audioEnabled, isTrue);

    // The result was persisted, not just returned.
    final persisted = await store.load();

    expect(persisted.config.manufacturer, 'Acme');
    expect(persisted.config.httpPort, 9080);
    expect(persisted.media.audioEnabled, isTrue);
  });

  testWidgets('invalid port blocks saving', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final getResult = await openScreen(tester, const ServerSettings());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'HTTP port'),
      'not-a-port',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Still on the settings screen with a validation error; nothing popped
    // and nothing was written.
    expect(getResult(), isNull);
    expect(find.text('Port must be 1–65535'), findsOneWidget);
    expect(File('${tempDir.path}/settings.json').existsSync(), isFalse);
  });

  testWidgets('cancelling with back returns null and persists nothing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final getResult = await openScreen(tester, const ServerSettings());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Manufacturer'),
      'Discarded',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(getResult(), isNull);
    expect(File('${tempDir.path}/settings.json').existsSync(), isFalse);
  });
}
