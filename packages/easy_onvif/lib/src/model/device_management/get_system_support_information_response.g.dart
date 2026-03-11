// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_system_support_information_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetSystemSupportInformationResponse
_$GetSystemSupportInformationResponseFromJson(Map<String, dynamic> json) =>
    GetSystemSupportInformationResponse(
      supportInformation: json['SupportInformation'] == null
          ? null
          : SystemInformation.fromJson(
              json['SupportInformation'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$GetSystemSupportInformationResponseToJson(
  GetSystemSupportInformationResponse instance,
) => <String, dynamic>{'SupportInformation': instance.supportInformation};
