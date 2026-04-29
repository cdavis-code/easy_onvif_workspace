export 'parse_mtom_stub.dart'
    if (dart.library.io) 'parse_mtom_io.dart'
    if (dart.library.html) 'parse_mtom_web.dart'
    if (dart.library.js_interop) 'parse_mtom_web.dart';
