// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileCapabilities _$ProfileCapabilitiesFromJson(Map<String, dynamic> json) =>
    ProfileCapabilities(
      maximumNumberOfProfiles: int.parse(
        json['@MaximumNumberOfProfiles'] as String,
      ),
      configurationEnumeration:
          (json['ConfigurationsSupported'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$ConfigurationEnumerationEnumMap, e))
              .toList(),
    );

Map<String, dynamic> _$ProfileCapabilitiesToJson(
  ProfileCapabilities instance,
) => <String, dynamic>{
  '@MaximumNumberOfProfiles': instance.maximumNumberOfProfiles,
  'ConfigurationsSupported': instance.configurationEnumeration
      ?.map((e) => _$ConfigurationEnumerationEnumMap[e]!)
      .toList(),
};

const _$ConfigurationEnumerationEnumMap = {
  ConfigurationEnumeration.all: 'All',
  ConfigurationEnumeration.videoSource: 'VideoSource',
  ConfigurationEnumeration.videoEncoder: 'VideoEncoder',
  ConfigurationEnumeration.audioSource: 'AudioSource',
  ConfigurationEnumeration.audioEncoder: 'AudioEncoder',
  ConfigurationEnumeration.audioOutput: 'AudioOutput',
  ConfigurationEnumeration.audioDecoder: 'AudioDecoder',
  ConfigurationEnumeration.metadata: 'Metadata',
  ConfigurationEnumeration.analytics: 'Analytics',
  ConfigurationEnumeration.ptz: 'PTZ',
};
