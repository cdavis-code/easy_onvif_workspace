# easy_onvif_mcp examples

```sh
dart pub get
dart run serve_stdio.dart --list-tools
```

Lists every tool the server hands to a model, and the arguments each one
requires — no camera and no MCP client needed.

To serve MCP over stdio (what an MCP host does), set credentials and run the
same file without the flag:

```sh
export ONVIF_HOST=192.168.1.10
export ONVIF_USERNAME=admin
export ONVIF_PASSWORD=secret
dart run serve_stdio.dart
```

The server then reads newline-delimited JSON-RPC from stdin and writes replies
to stdout; diagnostics go to stderr. Press Ctrl-C, or close stdin, to stop.

Registering it with a host instead of running it by hand:

```json
{
  "mcpServers": {
    "onvif": {
      "command": "dart",
      "args": ["run", "serve_stdio.dart"],
      "env": { "ONVIF_HOST": "192.168.1.10" }
    }
  }
}
```
