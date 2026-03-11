import 'dart:convert';

import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/util.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

part 'user.g.dart';

@JsonSerializable()
class User implements XmlSerializable {
  @JsonKey(name: 'Username', fromJson: OnvifUtil.stringMappedFromXml)
  final String username;

  @JsonKey(name: 'Password', fromJson: OnvifUtil.nullableStringMappedFromXml)
  final String? password;

  @JsonKey(name: 'UserLevel', fromJson: _mappedToUserLevel)
  final UserLevel userLevel;

  @JsonKey(name: 'Extension')
  final Map<String, dynamic>? extension;

  User({
    required this.username,
    this.password,
    required this.userLevel,
    this.extension,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  factory User.fromYamlMap(YamlMap yamlMap) => User(
    username: yamlMap['username'],
    password: yamlMap['password'],
    userLevel: UserLevel.values.contains(yamlMap['userLevel'])
        ? UserLevel.values.byName(yamlMap['userLevel'].toString())
        : UserLevel.user,
    extension: yamlMap['extension'],
  );

  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() => json.encode(toJson());

  static UserLevel _mappedToUserLevel(Map<String, dynamic> value) =>
      $enumDecode(_$UserLevelEnumMap, OnvifUtil.stringMappedFromXml(value));

  @override
  void buildXml(XmlBuilder builder, {String tag = 'User', String? namespace}) =>
      builder.element(
        tag,
        namespace: namespace,
        nest: () {
          username.buildXml(builder, tag: 'Username');
          password?.buildXml(builder, tag: 'Password');
          userLevel.code.buildXml(builder, tag: 'UserLevel');
        },
      );
}

@JsonEnum(valueField: 'code')
enum UserLevel {
  administrator('Administrator'),
  operator('Operator'),
  user('User'),
  anonymous('Anonymous'),
  extended('Extended');

  const UserLevel(this.code);
  final String code;
}
