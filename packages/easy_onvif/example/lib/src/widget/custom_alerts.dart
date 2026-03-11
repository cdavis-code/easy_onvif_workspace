import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAlerts {
  final Signal<bool> showAlert;

  final GlobalKey<FormBuilderState> formKey;

  final Future<SharedPreferences> sharedPreferences =
      SharedPreferences.getInstance();

  CustomAlerts({required this.showAlert, required this.formKey}) {
    init();
  }

  void init() async {
    final SharedPreferences preferences = await sharedPreferences;

    final useProxy = preferences.getBool('useProxy') ?? false;

    final ipAddress = preferences.getString('ipAddress');

    final port = preferences.getInt('port');

    formKey.currentState?.fields['wsProxy']?.setValue(useProxy);

    if (useProxy) {
      formKey.currentState?.fields['ipAddress']?.setValue(ipAddress);

      formKey.currentState?.fields['port']?.setValue(port);
    }
  }

  GFAlert authentication(BuildContext context) => const GFAlert(
    alignment: Alignment.center,
    backgroundColor: Colors.white,
    title: 'Authentication',
    content: Text(
      'Get Flutter is one of the largest Flutter open-source UI library for mobile or web apps with  1000+ pre-built reusable widgets.',
    ),
    type: GFAlertType.rounded,
  );

  GFAlert proxy(BuildContext context) {
    final showIpAddressField = Signal(false);

    return GFAlert(
      alignment: Alignment.center,
      backgroundColor: Colors.white,
      title: 'Proxy',
      content: SignalBuilder(
        builder: (context, child) {
          final visible = showIpAddressField();
          return FormBuilder(
            key: formKey,
            child: Column(
              children: [
                FormBuilderSwitch(
                  name: 'wsProxy',
                  title: const Text('ws Proxy'),
                  onChanged:
                      (value) =>
                          value != null
                              ? showIpAddressField.value = value
                              : null,
                ),
                Visibility(
                  visible: visible,
                  child: FormBuilderTextField(
                    name: 'ipAddress',
                    decoration: const InputDecoration(labelText: 'IP Address'),
                    validator: (value) {
                      if (visible) {
                        return FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.ip(),
                        ]).call(value);
                      }

                      return null;
                    },
                  ),
                ),
                Visibility(
                  visible: visible,
                  child: FormBuilderTextField(
                    name: 'port',
                    decoration: const InputDecoration(labelText: 'Port'),
                    validator: (value) {
                      if (visible) {
                        return FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.integer(),
                        ]).call(value);
                      }

                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton(
                    child: const Text('Continue'),
                    onPressed: () async {
                      final SharedPreferences preferences =
                          await sharedPreferences;

                      final useProxy =
                          formKey.currentState?.fields['wsProxy']?.value ??
                          false;

                      preferences.setBool('wsProxy', useProxy);

                      if (useProxy) {}

                      showAlert.value = false;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      type: GFAlertType.rounded,
    );
  }
}
