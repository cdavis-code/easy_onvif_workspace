/// Guards the registry, which is hand-authored on purpose: with no code
/// generator there is nothing else checking that schemas and argument reads
/// agree, and a mismatch only shows up as a confusing tool failure at runtime.
library;

import 'dart:convert';

import 'package:easy_onvif/ptz.dart';
import 'package:easy_onvif_mcp/easy_onvif_mcp.dart';
import 'package:test/test.dart';

void main() {
  group('tool registry', () {
    final tools = buildOnvifTools();

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
