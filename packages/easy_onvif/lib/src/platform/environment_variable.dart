export 'environment_variable_stub.dart'
    if (dart.library.io) 'environment_variable_io.dart'
    if (dart.library.html) 'environment_variable_web.dart'
    if (dart.library.js_interop) 'environment_variable_web.dart';
