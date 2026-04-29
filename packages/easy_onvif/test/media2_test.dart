import 'package:easy_onvif/media2.dart';
import 'package:easy_onvif/shared.dart';
import 'package:test/test.dart';

import 'envelope.dart';

void main() {
  group('Media2', () {
    group('Happytimesoft', () {
      test('GetMetadataConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media2/GetMetadataConfigurationOptionsResponse.xml',
        );

        expect(
          GetMetadataConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).options.ptzStatusFilterOptions?.zoomStatusSupported,
          true,
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media2/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media2/GetProfilesResponse.xml',
        );

        expect(
          GetProfilesResponse.fromJson(
            envelope.body.response!,
          ).profiles.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media2/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.snapshotUri,
          true,
        );
      });

      test('GetSnapshotUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media2/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).uri,
          'http://192.168.2.119:10000/snapshot/ProfileToken_1',
        );
      });

      test('GetStreamUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media2/GetStreamUriResponse.xml',
        );

        expect(
          GetStreamUriResponse.fromJson(envelope.body.response!).uri ==
              'rtsp://192.168.2.119/test.mp4&ve=H264&w=1280&h=720&ae=PCMU&sr=8000',
          true,
        );
      });

      test('StartMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media2/StartMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey(
            'StartMulticastStreamingResponse',
          ),
          true,
        );
      });

      test('StopMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media2/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });

    group('ENP1A14-IR_25X', () {
      test('GetMetadataConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media2/GetMetadataConfigurationOptionsResponse.xml',
        );

        expect(
          GetMetadataConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).options.ptzStatusFilterOptions?.zoomStatusSupported,
          false,
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media2/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media2/GetProfilesResponse.xml',
        );

        expect(
          GetProfilesResponse.fromJson(
            envelope.body.response!,
          ).profiles.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media2/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.snapshotUri,
          true,
        );
      });

      test('GetSnapshotUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media2/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).uri,
          'http://192.168.1.182/onvif-http/snapshot?Profile_1',
        );
      });

      test('GetStreamUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media2/GetStreamUriResponse.xml',
        );

        expect(
          GetStreamUriResponse.fromJson(envelope.body.response!).uri ==
              'rtsp://192.168.1.182/Streaming/Channels/101?transportmode=unicast&profile=Profile_1',
          true,
        );
      });

      test('StartMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media2/StartMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey(
            'StartMulticastStreamingResponse',
          ),
          true,
        );
      });

      test('StopMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media2/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });

    group('GX728MF-IR28', () {
      test('GetMetadataConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/media2/GetMetadataConfigurationOptionsResponse.xml',
        );

        expect(
          GetMetadataConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).options.ptzStatusFilterOptions?.zoomStatusSupported,
          false,
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/media2/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/media2/GetProfilesResponse.xml',
        );

        expect(
          GetProfilesResponse.fromJson(
            envelope.body.response!,
          ).profiles.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/media2/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.snapshotUri,
          true,
        );
      });

      test('GetSnapshotUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/media2/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).uri,
          'http://192.168.1.127:85/images/snapshot.jpg',
        );
      });
    });

    group('IPG-8150PSS', () {
      test('GetMetadataConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/GetMetadataConfigurationOptionsResponse.xml',
        );

        expect(
          GetMetadataConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).options.ptzStatusFilterOptions?.zoomStatusSupported,
          true,
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/GetProfilesResponse.xml',
        );

        expect(
          GetProfilesResponse.fromJson(
            envelope.body.response!,
          ).profiles.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.snapshotUri,
          true,
        );
      });

      test('GetSnapshotUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).uri,
          'http://10.200.1.2:80/SnapShot_Ch0.jpg',
        );
      });

      test('GetStreamUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/GetStreamUriResponse.xml',
        );

        expect(
          GetStreamUriResponse.fromJson(envelope.body.response!).uri,
          'rtsp://10.200.1.2/live/0/MAIN',
        );
      });

      test('GetVideoEncoderConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/GetVideoEncoderConfigurationsResponse.xml',
        );

        expect(
          GetVideoEncoderConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetVideoSourceConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/GetVideoSourceConfigurationOptionsResponse.xml',
        );

        expect(
          GetVideoSourceConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).options.videoSourceTokensAvailable.isNotEmpty,
          true,
        );
      });

      test('StartMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/StartMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey(
            'StartMulticastStreamingResponse',
          ),
          true,
        );
      });

      test('StopMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });

    group('SUNBA', () {
      test('GetMetadataConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media2/GetMetadataConfigurationOptionsResponse.xml',
        );

        expect(
          GetMetadataConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).options.ptzStatusFilterOptions?.zoomStatusSupported,
          true,
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media2/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media2/GetProfilesResponse.xml',
        );

        expect(
          GetProfilesResponse.fromJson(
            envelope.body.response!,
          ).profiles.isNotEmpty,
          true,
        );
      });

      test('GetServiceCapabilitiesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media2/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.snapshotUri,
          true,
        );
      });

      test('GetSnapshotUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media2/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).uri,
          'http://162.191.54.181:80/LAPI/V1.0/Media/Video/Streams/0/Snapshot',
        );
      });

      test('GetStreamUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media2/GetStreamUriResponse.xml',
        );

        expect(
          GetStreamUriResponse.fromJson(envelope.body.response!).uri,
          'rtsp://162.191.54.181/media/video1',
        );
      });

      test('GetVideoEncoderConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media2/GetVideoEncoderConfigurationsResponse.xml',
        );

        expect(
          GetVideoEncoderConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetVideoSourceConfigurationOptionsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media2/GetVideoSourceConfigurationOptionsResponse.xml',
        );

        expect(
          GetVideoSourceConfigurationOptionsResponse.fromJson(
            envelope.body.response!,
          ).options.videoSourceTokensAvailable.isNotEmpty,
          true,
        );
      });

      test('StartMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/StartMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey(
            'StartMulticastStreamingResponse',
          ),
          true,
        );
      });

      test('StopMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media2/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });
  });
}
