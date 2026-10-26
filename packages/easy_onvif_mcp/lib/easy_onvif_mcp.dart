/// The ONVIF MCP server.
///
/// `EasyOnvifMcpServer` carries the `@Server` / `@Tool` annotations the
/// `easy_api_generator` reads, so its stdio dispatcher is generated code — see
/// `bin/easy_onvif_mcp_server.dart`. This barrel re-exports the annotated class
/// and the host hooks it expects; the Node.js bundle additionally uses
/// `src/js/js_server.dart`, which is not exported here because it is an
/// implementation detail of the npm artifact.
library;

export 'meta.dart';
export 'src/easy_onvif_mcp_server.dart'
    show
        EasyOnvifMcpServer,
        DioFactory,
        envHost,
        envUsername,
        envPassword,
        stderrWriteln;
