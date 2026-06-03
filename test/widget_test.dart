import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_cd/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('your_cd/native');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'loadSkills' => '[]',
            'saveSkills' => null,
            'cancelNotification' => null,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('shows the empty skill dashboard', (tester) async {
    await tester.pumpWidget(const YourCdApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('YourCD'), findsOneWidget);
    expect(find.text('还没有技能'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });
}
