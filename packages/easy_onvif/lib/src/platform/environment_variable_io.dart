import 'dart:io';

String? getEnvironmentVariable(String variableName, {String? defaultValue}) =>
    defaultValue != null
    ? Platform.environment[variableName] ?? defaultValue
    : Platform.environment[variableName];
