import 'dart:io';

import 'package:easy_onvif/util.dart';
import 'package:path/path.dart' as p;

File get defaultConfigFile => userHome != ''
    ? File(p.join(userHome, '.onvif/credentials.json'))
    : throw Exception('User home directory not found');

String get userHome => getEnvironmentVariable(
  'HOME',
  defaultValue: getEnvironmentVariable('USERPROFILE', defaultValue: ''),
)!;
