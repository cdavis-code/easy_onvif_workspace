/// Guards the Node.js tool registry and its parity with the generated
/// dispatcher.
///
/// The Dart VM dispatcher is generated from the `@Tool` annotations, but the
/// npm bundle keeps a hand-written registry (the generated code imports
/// `dart:io`). These tests are what stop the two lists drifting apart.
library;

import 'dart:convert';
import 'dart:io';

import 'package:easy_onvif/ptz.dart';
import 'package:easy_onvif_mcp/src/js/tool_defs.dart';
import 'package:easy_onvif_mcp/src/js/tools.dart';
import 'package:easy_onvif_mcp/src/json_safe.dart';
import 'package:test/test.dart';

void main() {
  group('tool registry', () {
    final tools = buildOnvifTools();

    test('matches the generated Dart VM dispatcher exactly', () {
      final source = File(
        'lib/src/easy_onvif_mcp_server.mcp.dart',
      ).readAsStringSync();
      final generated = RegExp(
        r"name: '(onvif_[a-z0-9_]+)'",
      ).allMatches(source).map((m) => m.group(1)!).toSet();
      final registry = tools.map((t) => t.name).toSet();

      expect(generated, isNotEmpty, reason: 'run build_runner first');
      // Both directions: a tool missing from either list is a parity bug.
      expect(registry.difference(generated), isEmpty);
      expect(generated.difference(registry), isEmpty);
    });

    test('names are unique and prefixed', () {
      final names = tools.map((t) => t.name).toList();
      expect(
        names.toSet(),
        hasLength(names.length),
        reason: 'duplicate tool name',
      );
      for (final name in names) {
        expect(name, startsWith('onvif_'));
      }
    });

    test('every required property is declared', () {
      for (final tool in tools) {
        final properties = tool.inputSchema.properties ?? const {};
        for (final required in tool.inputSchema.required ?? const <String>[]) {
          expect(
            properties,
            contains(required),
            reason: '${tool.name} requires undocumented "$required"',
          );
        }
      }
    });

    test('every tool is described', () {
      for (final tool in tools) {
        expect(tool.description, isNotEmpty, reason: tool.name);
      }
    });
  });

  group('credentials are never echoed', () {
    // dart_mcp's schema-validation failure quotes the rejected value
    // (``Value `12345` is not of type `String` at path #root["password"]``).
    // Numeric default passwords are common on ONVIF devices, so a mistyped
    // credential must not be able to reach the model transcript.
    test('requiredString omits the rejected value', () {
      expect(
        () => requiredString({'password': 12345}, 'password'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            isNot(contains('12345')),
          ),
        ),
      );
    });

    test('any tool accepting a password opts out of schema validation', () {
      for (final tool in buildOnvifTools()) {
        final properties = tool.inputSchema.properties ?? const {};
        if (properties.containsKey('password')) {
          expect(
            tool.validateArguments,
            isFalse,
            reason: '${tool.name} would echo a credential on a type error',
          );
        }
      }
    });
  });

  group('jsonSafe', () {
    test('keeps @-prefixed attribute keys, which carry the tokens', () {
      final encoded = jsonSafe(Preset.fromToken('4', name: 'Doorway'));
      expect(encoded, isA<Map<String, Object?>>());
      expect((encoded as Map)['@token'], '4');
    });

    test('encodes a model graph as plain JSON', () {
      expect(
        () => jsonEncode(jsonSafe([Preset.fromToken('1', name: 'A')])),
        returnsNormally,
      );
    });
  });
}
