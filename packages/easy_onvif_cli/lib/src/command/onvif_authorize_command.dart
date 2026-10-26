import 'package:args/command_runner.dart';
import 'package:easy_onvif_cli/command.dart';

/// Deprecated alias for `onvif credentials init`.
///
/// It writes the encrypted credential file — never plaintext — and asks before
/// overwriting an existing one, so existing scripts keep working while the
/// `credentials` command group becomes the documented path.
class OnvifAuthorizeCommand extends Command<void> {
  @override
  String get description =>
      'Create the encrypted credential file (alias for `credentials init`).';

  @override
  String get name => 'authorize';

  @override
  void run() async => runCredentialsInit(globalResults!, overwritePrompt: true);
}
