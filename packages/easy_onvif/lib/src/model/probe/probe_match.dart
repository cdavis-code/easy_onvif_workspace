import 'dart:convert';

import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:loggy/loggy.dart';

import 'endpoint_reference.dart';

part 'probe_match.g.dart';

@JsonSerializable()
class ProbeMatch with UiLoggy {
  @JsonKey(name: 'EndpointReference')
  final EndpointReference endpointReference;

  @JsonKey(name: 'Types', fromJson: _listFromJson) // _toList
  final List<String> types;

  @JsonKey(name: 'Scopes', fromJson: _listFromJson)
  final List<String> scopes;

  @JsonKey(name: 'XAddrs', fromJson: _listFromJson)
  final List<String> xAddrs;

  @JsonKey(
    name: 'MetadataVersion',
    fromJson: _metadata,
  ) //OnvifUtil.stringMappedFromXml
  final String metadataVersion;

  final _profiles = <String>[];

  String? _location;
  String? _type;
  String? _name;
  String? _hardware;

  String get xAddr => xAddrs.first;

  String get location => _location ?? '';

  String get type => _type ?? '';

  String get name => _name ?? '';

  String get hardware => _hardware ?? '';

  // InternetAddress get internetAddress => InternetAddress(Uri.parse(xAddr).host);

  List<String> get profiles => _profiles;

  ProbeMatch({
    required this.endpointReference,
    required this.types,
    required this.scopes,
    required this.xAddrs,
    required this.metadataVersion,
  }) {
    _setCommonScopes();
  }

  factory ProbeMatch.fromJson(Map<String, dynamic> json) =>
      _$ProbeMatchFromJson(json);

  Map<String, dynamic> toJson() => _$ProbeMatchToJson(this);

  @override
  String toString() => json.encode(toJson());

  void _setCommonScopes() {
    for (var scope in scopes) {
      try {
        final scopeAsUri = scope.parseUri;

        var pathSegments = List<String>.from(scopeAsUri.pathSegments);

        var identifier = pathSegments[0];

        pathSegments.removeAt(0);

        var data = pathSegments.join('/');

        switch (identifier) {
          case 'location':
            _location = data;

            break;

          case 'type':
            _type = data;

            break;

          case 'name':
            _name = data;

            break;

          case 'hardware':
            _hardware = data;

            break;

          case 'profile':
            _profiles.add(data);

            break;
        }
      } catch (exception) {
        loggy.error(exception);
      }
    }
  }

  static List<String> _listFromXmlJson(Map<String, dynamic> value) =>
      OnvifUtil.stringMappedFromXml(
        value,
      ).split(RegExp([' ', ',', r'\r\\n'].map(RegExp.escape).join('|')));

  static List<String> _listFromJson(dynamic json) {
    if (json == null) {
      return [];
    }

    if (json is Map) {
      // json from XML
      return _listFromXmlJson(json as Map<String, dynamic>);
    } else {
      // json from serialized object
      return (json as List).map((e) => e as String).toList();
    }
  }

  static String _metadata(dynamic json) {
    if (json is Map) {
      // json from XML
      return OnvifUtil.stringMappedFromXml(json as Map<String, dynamic>);
    } else {
      // json from serialized object
      return json as String;
    }
  }
}
