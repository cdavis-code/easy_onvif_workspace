import 'dart:ffi';
import 'dart:io';

import 'package:easy_onvif/probe.dart';
import 'package:easy_onvif/soap.dart';
import 'package:ffi/ffi.dart';
import 'package:loggy/loggy.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import 'base_multicast_probe.dart';

@Packed(1)
sealed class _OnvifDiscoveryData extends Struct {
  @Array<Int8>(128, 8192)
  external Array<Array<Int8>> buf;
}

class MulticastProbeImpl extends BaseMulticastProbe {
  final MulticastProbeIo _multicastProbeIo;

  MulticastProbeImpl({int? timeout, bool? releaseMode})
    : _multicastProbeIo = MulticastProbeIo(
        timeout: timeout,
        releaseMode: releaseMode,
      );

  List<ProbeMatch> get onvifDevices => _multicastProbeIo.onvifDevices;

  @override
  Future<void> probe() => _multicastProbeIo.probe();

  @override
  Future<void> hello() => _multicastProbeIo.sendHello();

  @override
  Future<void> bye() => _multicastProbeIo.sendBye();
}

class MulticastProbeIo with UiLoggy {
  late final int Function(Pointer<NativeType>, Pointer<NativeType>, int)
  _discovery;

  static final broadcastAddress = InternetAddress('239.255.255.250');

  static final broadcastPort = 3702;

  final onvifDevices = <ProbeMatch>[];

  int? probeTimeout;

  int? announceInterval;

  factory MulticastProbeIo({
    int? timeout,
    int? announceInterval,
    bool? releaseMode,
  }) {
    if (Platform.isWindows) {
      return MulticastProbeIo.windows(
        timeout: timeout,
        releaseMode: releaseMode,
      );
    } else {
      return MulticastProbeIo.other(
        timeout: timeout,
        announceInterval: announceInterval,
      );
    }
  }

  MulticastProbeIo.other({int? timeout, int? announceInterval}) {
    probeTimeout = timeout ?? BaseMulticastProbe.defaultTimeout;

    announceInterval =
        announceInterval ?? BaseMulticastProbe.defaultAnnounceInterval;
  }

  /// Constructor for Windows OS builds, we need the `kReleaseMode` flag from
  /// Flutter to determine if we are running in debug or release mode so that
  /// the appropriate path to the `discovery.dll` file can be used.  The default
  /// assumes the application is running as a `cli` app and will look for the
  /// DLL in the same folder as the executable.  For `cli` the path to the DLL
  /// can be overwritten with the `ONVIF_DISCOVERY_DLL` environment variable.
  MulticastProbeIo.windows({int? timeout, bool? releaseMode}) {
    final env = Platform.environment;

    var discoveryDllPath = env.containsKey('ONVIF_DISCOVERY_DLL')
        ? env['ONVIF_DISCOVERY_DLL']!
        : join(Directory.current.path, 'bin', 'discovery.dll');

    if (releaseMode != null) {
      discoveryDllPath = join(
        Directory.current.path,
        'assets',
        'discovery.dll',
      );

      if (releaseMode) {
        final String localLib = join(
          'data',
          'flutter_assets',
          'assets',
          'discovery.dll',
        );

        discoveryDllPath = join(
          Directory(Platform.resolvedExecutable).parent.path,
          localLib,
        );
      }
    }

    final Pointer<T> Function<T extends NativeType>(String symbolName) lookup =
        () {
          return DynamicLibrary.open(discoveryDllPath).lookup;
        }();

    final discoveryPtr =
        lookup<
          NativeFunction<
            Int32 Function(Pointer<NativeType>, Pointer<NativeType>, Int32)
          >
        >('discovery');

    _discovery = discoveryPtr
        .asFunction<
          int Function(Pointer<NativeType>, Pointer<NativeType>, int)
        >();

    probeTimeout = timeout ?? BaseMulticastProbe.defaultTimeout;
  }

  Future<void> probe() async {
    loggy.debug('init');

    if (Platform.isWindows) {
      await windowsDiscovery(Duration(seconds: probeTimeout!));

      return;
    }

    await RawDatagramSocket.bind(broadcastAddress, broadcastPort);

    final rawDataGramSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: false,
      reusePort: false,
    );

    rawDataGramSocket.listen((RawSocketEvent rawSocketEvent) {
      var dataGram = rawDataGramSocket.receive();

      if (dataGram == null) return;

      String messageReceived = String.fromCharCodes(dataGram.data);

      loggy.debug('RESPONSE ADDRESS:\n${dataGram.address}');

      loggy.debug('RESPONSE:\n$messageReceived');

      var envelope = Envelope.fromXmlString(messageReceived);

      if (envelope.body.response == null) throw Exception();

      onvifDevices.addAll(
        ProbeMatches.fromJson(envelope.body.response!).probeMatches,
      );
    });

    _start(rawDataGramSocket);

    await _finish(rawDataGramSocket, probeTimeout);
  }

  Future<void> sendHello() async {
    loggy.debug('sendHello');

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    final helloMessage = WsDiscovery.hello(
      messageNumber: 1,
      xAddrs: ['http://${socket.address.address}/onvif/device_service'],
    );

    socket.send(
      helloMessage.toXmlString().codeUnits,
      broadcastAddress,
      broadcastPort,
    );

    socket.close();
  }

  Future<void> sendBye() async {
    loggy.debug('sendBye');

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    final byeMessage = WsDiscovery.bye(
      messageId: Uuid().v4(),
      address: Uuid().v4(),
    );

    socket.send(
      byeMessage.toXmlString().codeUnits,
      broadcastAddress,
      broadcastPort,
    );

    socket.close();
  }

  void _start(RawDatagramSocket rawDataGramSocket) {
    loggy.debug('hello');

    final helloMessageBodyXml = WsDiscovery.hello(
      messageNumber: 1,
      xAddrs: ['http://${rawDataGramSocket.address}/onvif/device_service'],
    );

    rawDataGramSocket.send(
      helloMessageBodyXml.toXmlString().codeUnits,
      broadcastAddress,
      broadcastPort,
    );

    loggy.debug('probe');

    loggy.debug(
      'BROADCAST ADDRESS: ${broadcastAddress.address}, PORT: $broadcastPort',
    );

    final probeMessageBodyXml = WsDiscovery.probe();

    loggy.debug('REQUEST:\n${probeMessageBodyXml.toXmlString(pretty: true)}');

    rawDataGramSocket.send(
      probeMessageBodyXml.toXmlString().codeUnits,
      broadcastAddress,
      broadcastPort,
    );
  }

  /// timeout of 0 or less means no timeout
  Future<void> _finish(
    RawDatagramSocket rawDataGramSocket, [
    int? timeout,
  ]) async {
    await Future.delayed(
      Duration(seconds: timeout ?? BaseMulticastProbe.defaultTimeout),
    );

    loggy.debug('bye');

    final byeMessageBodyXml = WsDiscovery.bye(
      messageId: Uuid().v4(),
      address: Uuid().v4(),
    );

    rawDataGramSocket.send(
      byeMessageBodyXml.toXmlString().codeUnits,
      broadcastAddress,
      broadcastPort,
    );

    rawDataGramSocket.close();
  }

  Future<void> windowsDiscovery(Duration duration) async {
    final data = calloc<_OnvifDiscoveryData>();

    final probeMessageData = WsDiscovery.probe().toXmlString().toNativeUtf8();

    final devices = _discovery(data, probeMessageData, duration.inMilliseconds);

    for (var index = 0; index < devices; index++) {
      var envelope = Envelope.fromXmlString(
        Pointer.fromAddress(
          data.address + index * 8192,
        ).cast<Utf8>().toDartString(),
      );

      onvifDevices.addAll(
        ProbeMatches.fromJson(envelope.body.response!).probeMatches,
      );
    }

    malloc.free(probeMessageData);
    calloc.free(data);
  }
}
