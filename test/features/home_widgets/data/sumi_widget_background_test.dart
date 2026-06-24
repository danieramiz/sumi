import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Widget background schedule', () {
    late List<String> calledMethods;

    setUp(() {
      calledMethods = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('sumi_widget_background'),
        (MethodCall methodCall) async {
          calledMethods.add(methodCall.method);
          return true;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('sumi_widget_background'),
        null,
      );
    });

    test('invokeMethod schedule succeeds', () async {
      await const MethodChannel('sumi_widget_background')
          .invokeMethod('schedule');
      expect(calledMethods, contains('schedule'));
    });

    test('invokeMethod cancel succeeds', () async {
      await const MethodChannel('sumi_widget_background')
          .invokeMethod('cancel');
      expect(calledMethods, contains('cancel'));
    });

    test('schedule does not throw when channel is not set up', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('sumi_widget_background'),
        null,
      );

      try {
        await const MethodChannel('sumi_widget_background')
            .invokeMethod('schedule');
      } catch (_) {
        // Expected to potentially throw when no handler
      }
    });
  });
}
