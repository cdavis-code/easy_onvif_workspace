import 'package:easy_onvif/shared.dart';
import 'package:easy_onvif/soap.dart' show Xmlns;
import 'package:xml/xml.dart';

import 'fault.dart';

class Body implements XmlSerializable {
  final Fault? fault;

  final XmlDocumentFragment? request;

  final Map<String, dynamic>? response;

  bool get hasFault => fault != null;

  bool get success => fault == null;

  Body({this.fault, this.request, this.response});

  factory Body.fromJson(Map<String, dynamic> json) {
    // Check if there's a fault first
    final fault = json['Fault'] == null
        ? null
        : Fault.fromJson(json['Fault'] as Map<String, dynamic>);

    // Find response key (any key that's not 'Fault')
    final responseKeys = json.keys.where((key) => key != 'Fault').toList();

    Map<String, dynamic> responseMap = <String, dynamic>{};

    if (responseKeys.isNotEmpty) {
      final responseType = responseKeys.first;
      final responseValue = json[responseType];

      // Handle case where the response value might be a string or other type
      if (responseValue is Map<String, dynamic>) {
        responseMap = responseValue;
      } else if (responseValue is String) {
        // If it's a string, wrap it in a map
        responseMap = {responseType: responseValue};
      } else if (responseValue != null) {
        // For other types, wrap them in a map
        responseMap = {responseType: responseValue};
      }
    }

    return Body(
      fault: fault,
      response: responseMap.isEmpty ? json : responseMap,
    );
  }

  @override
  void buildXml(
    XmlBuilder builder, {
    String tag = 'Body',
    String? namespace = Xmlns.s,
  }) {
    builder.element(
      tag,
      namespace: namespace,
      namespaces: {
        'http://www.w3.org/2001/XMLSchema-instance': 'xsi',
        Xmlns.xsd: 'xsd',
      },
      nest: request,
    );
  }
}
