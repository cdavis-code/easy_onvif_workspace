import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

extension UsageExtension on DioException {
  String get usage {
    return response?.data['error']['errors'] == null
        ? message!
        : response!.data['error']['errors'].toString();
  }
}

extension Helpers on String {
  Uri get parseUri {
    return Uri.parse(this);
  }

  void buildXml(XmlBuilder builder, {required String tag, String? namespace}) =>
      builder.element(
        tag,
        nest: () {
          if (namespace != null) {
            builder.namespaceUri(null, namespace);
          }

          builder.text(this);
        },
      );
}

extension MapExtension on Map<String, dynamic> {
  Map<String, dynamic> convertFieldsToXmlMap(List<String> fields) {
    for (var key in keys) {
      if (fields.contains(key)) this[key] = {'\$': this[key]};
    }

    return this;
  }

  Map<String, dynamic> convertFieldToXmlMap(String field) =>
      convertFieldsToXmlMap([field]);
}
