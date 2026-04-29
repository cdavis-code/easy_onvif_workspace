import 'package:easy_onvif/media1.dart';
import 'package:easy_onvif/shared.dart';
import 'package:test/test.dart';

import 'envelope.dart';

void main() {
  group('Media1', () {
    group('Happytimesoft', () {
      test('GetAudioSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media1/GetAudioSourcesResponse.xml',
        );

        expect(
          GetAudioSourcesResponse.fromJson(
            envelope.body.response!,
          ).audioSources.isNotEmpty,
          true,
        );
      });

      test('GetMetadataConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media1/GetMetadataConfigurationResponse.xml',
        );

        expect(
          GetMetadataConfigurationResponse.fromJson(
            envelope.body.response!,
          ).configuration?.name,
          'MetadataConfigurationName_1',
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media1/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfileResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media1/GetProfileResponse.xml',
        );

        expect(
          GetProfileResponse.fromJson(envelope.body.response!).profile.fixed,
          true,
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media1/GetProfilesResponse.xml',
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
          '../../test_data/xml/happytimesoft/media1/GetServiceCapabilitiesResponse.xml',
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
          '../../test_data/xml/happytimesoft/media1/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'http://192.168.2.119:10000/snapshot/ProfileToken_1',
        );
      });

      test('GetStreamUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media1/GetStreamUriResponse.xml',
        );

        expect(
          GetStreamUriResponse.fromJson(
                envelope.body.response!,
              ).mediaUri.timeout ==
              'PT60S',
          true,
        );
      });

      test('GetVideoSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media1/GetVideoSourcesResponse.xml',
        );

        expect(
          GetVideoSourcesResponse.fromJson(
            envelope.body.response!,
          ).videoSources.isNotEmpty,
          true,
        );
      });

      test('StartMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/happytimesoft/media1/StartMulticastStreamingResponse.xml',
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
          '../../test_data/xml/happytimesoft/media1/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });

    group('ENP1A14-IR_25X', () {
      test('GetAudioSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetAudioSourcesResponse.xml',
        );

        expect(
          GetAudioSourcesResponse.fromJson(
            envelope.body.response!,
          ).audioSources.isNotEmpty,
          true,
        );
      });

      test('GetMetadataConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetMetadataConfigurationResponse.xml',
        );

        expect(
          GetMetadataConfigurationResponse.fromJson(
            envelope.body.response!,
          ).configuration?.name,
          'metaData',
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfileResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetProfileResponse.xml',
        );

        expect(
          GetProfileResponse.fromJson(envelope.body.response!).profile.token,
          'Profile_1',
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetProfilesResponse.xml',
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
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetServiceCapabilitiesResponse.xml',
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
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'http://192.168.1.182/onvif-http/snapshot?Profile_1',
        );
      });

      test('GetStreamUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetStreamUriResponse.xml',
        );

        expect(
          GetStreamUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'rtsp://192.168.1.182:554/Streaming/Channels/101?transportmode=mcast&profile=Profile_1',
        );
      });

      test('GetVideoSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media1/GetVideoSourcesResponse.xml',
        );

        expect(
          GetVideoSourcesResponse.fromJson(
            envelope.body.response!,
          ).videoSources.isNotEmpty,
          true,
        );
      });

      test('StartMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/ENP1A14-IR_25X/media1/StartMulticastStreamingResponse.xml',
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
          '../../test_data/xml/ENP1A14-IR_25X/media1/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });

    group('DCS-6511', () {
      test('GetAudioSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/media1/GetAudioSourcesResponse.xml',
        );

        expect(
          GetAudioSourcesResponse.fromJson(
            envelope.body.response!,
          ).audioSources.isNotEmpty,
          true,
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/media1/GetMetadataConfigurationsResponse.xml',
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
          '../../test_data/xml/DCS-6511/media1/GetProfilesResponse.xml',
        );

        expect(
          GetProfilesResponse.fromJson(
            envelope.body.response!,
          ).profiles.isNotEmpty,
          true,
        );
      });

      test('GetSnapshotUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/media1/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'http://192.168.1.33/dms?nowprofileid=1',
        );
      });

      test('GetVideoSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/media1/GetVideoSourcesResponse.xml',
        );

        expect(
          GetVideoSourcesResponse.fromJson(
            envelope.body.response!,
          ).videoSources.isNotEmpty,
          true,
        );
      });

      test('StartMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/DCS-6511/media1/StartMulticastStreamingResponse.xml',
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
          '../../test_data/xml/DCS-6511/media1/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });

    group('GX728MF-IR28', () {
      test('GetAudioSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/media1/GetAudioSourcesResponse.xml',
        );

        expect(
          GetAudioSourcesResponse.fromJson(
            envelope.body.response!,
          ).audioSources.isEmpty,
          true,
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/media1/GetMetadataConfigurationsResponse.xml',
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
          '../../test_data/xml/GX728MF-IR28/media1/GetProfilesResponse.xml',
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
          '../../test_data/xml/GX728MF-IR28/media1/GetServiceCapabilitiesResponse.xml',
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
          '../../test_data/xml/GX728MF-IR28/media1/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'http://192.168.1.127:85/images/snapshot.jpg',
        );
      });

      test('GetVideoSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/GX728MF-IR28/media1/GetVideoSourcesResponse.xml',
        );

        expect(
          GetVideoSourcesResponse.fromJson(
            envelope.body.response!,
          ).videoSources.isNotEmpty,
          true,
        );
      });
    });

    group('IPG-8150PSS', () {
      test('GetAudioSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media1/GetAudioSourcesResponse.xml',
        );

        expect(
          GetAudioSourcesResponse.fromJson(
            envelope.body.response!,
          ).audioSources.isEmpty,
          false,
        );
      });

      test('GetMetadataConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media1/GetMetadataConfigurationResponse.xml',
        );

        expect(
          GetMetadataConfigurationResponse.fromJson(
            envelope.body.response!,
          ).configuration?.name,
          'MetadataConfiguration',
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media1/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfileResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media1/GetProfileResponse.xml',
        );

        expect(
          GetProfileResponse.fromJson(envelope.body.response!).profile.name,
          'PROFILE_000',
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media1/GetProfilesResponse.xml',
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
          '../../test_data/xml/IPG-8150PSS/media1/GetServiceCapabilitiesResponse.xml',
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
          '../../test_data/xml/IPG-8150PSS/media1/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'http://10.200.1.2:80/SnapShot_Ch0.jpg',
        );
      });

      test('GetStreamUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media1/GetStreamUriResponse.xml',
        );

        expect(
          GetStreamUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'rtsp://10.200.1.2/live/0/MAIN',
        );
      });

      test('GetVideoSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media1/GetVideoSourcesResponse.xml',
        );

        expect(
          GetVideoSourcesResponse.fromJson(
            envelope.body.response!,
          ).videoSources.isNotEmpty,
          true,
        );
      });

      test('StartMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPG-8150PSS/media1/StartMulticastStreamingResponse.xml',
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
          '../../test_data/xml/IPG-8150PSS/media1/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });

    group('SUNBA', () {
      test('GetAudioSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media1/GetAudioSourcesResponse.xml',
        );

        expect(
          GetAudioSourcesResponse.fromJson(
            envelope.body.response!,
          ).audioSources.isEmpty,
          false,
        );
      });

      test('GetMetadataConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media1/GetMetadataConfigurationResponse.xml',
        );

        expect(
          GetMetadataConfigurationResponse.fromJson(
            envelope.body.response!,
          ).configuration?.name,
          'metadata_config',
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media1/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfileResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media1/GetProfileResponse.xml',
        );

        expect(
          GetProfileResponse.fromJson(envelope.body.response!).profile.name,
          'media_profile1',
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media1/GetProfilesResponse.xml',
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
          '../../test_data/xml/SUNBA/media1/GetServiceCapabilitiesResponse.xml',
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
          '../../test_data/xml/SUNBA/media1/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'http://162.191.54.181:80/LAPI/V1.0/Media/Video/Streams/0/Snapshot',
        );
      });

      // test('GetStreamUriResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //       '../../test_data/xml/IPG-8150PSS/media1/GetStreamUriResponse.xml');

      //   expect(
      //       GetStreamUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
      //       'rtsp://10.200.1.2/live/0/MAIN');
      // });

      test('GetVideoSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/SUNBA/media1/GetVideoSourcesResponse.xml',
        );

        expect(
          GetVideoSourcesResponse.fromJson(
            envelope.body.response!,
          ).videoSources.isNotEmpty,
          true,
        );
      });

      // test('StopMulticastStreamingResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //     '../../test_data/xml/SUNBA/media1/StopMulticastStreamingResponse.xml',
      //   );

      //   expect(
      //     envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
      //     true,
      //   );
      // });
    });

    group('IPD-H4K8M05-BS', () {
      // test('GetAudioSourcesResponse', () {
      //   final envelope = Envelope.fromXmlFile(
      //     '../../test_data/xml/IPD-H4K8M05-BS/media1/GetAudioSourcesResponse.xml',
      //   );

      //   expect(
      //     GetAudioSourcesResponse.fromJson(
      //       envelope.body.response!,
      //     ).audioSources.isEmpty,
      //     false,
      //   );
      // });

      test('GetMetadataConfigurationResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/media1/GetMetadataConfigurationResponse.xml',
        );

        expect(
          GetMetadataConfigurationResponse.fromJson(
            envelope.body.response!,
          ).configuration?.name,
          'METADATA_CH0',
        );
      });

      test('GetMetadataConfigurationsResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/media1/GetMetadataConfigurationsResponse.xml',
        );

        expect(
          GetMetadataConfigurationsResponse.fromJson(
            envelope.body.response!,
          ).configurations.isNotEmpty,
          true,
        );
      });

      test('GetProfileResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/media1/GetProfileResponse.xml',
        );

        expect(
          GetProfileResponse.fromJson(envelope.body.response!).profile.name,
          'MainStream',
        );
      });

      test('GetProfilesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/media1/GetProfilesResponse.xml',
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
          '../../test_data/xml/IPD-H4K8M05-BS/media1/GetServiceCapabilitiesResponse.xml',
        );

        expect(
          GetServiceCapabilitiesResponse.fromJson(
            envelope.body.response!,
          ).capabilities.streamingCapabilities.rtp_tcp,
          true,
        );
      });

      test('GetSnapshotUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/media1/GetSnapshotUriResponse.xml',
        );

        expect(
          GetSnapshotUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'http://192.168.15.40/jpgimage/1/image.jpg',
        );
      });

      test('GetStreamUriResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/media1/GetStreamUriResponse.xml',
        );

        expect(
          GetStreamUriResponse.fromJson(envelope.body.response!).mediaUri.uri,
          'rtsp://192.168.15.40:554/1/h264major',
        );
      });

      test('GetVideoSourcesResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/media1/GetVideoSourcesResponse.xml',
        );

        expect(
          GetVideoSourcesResponse.fromJson(
            envelope.body.response!,
          ).videoSources.isNotEmpty,
          true,
        );
      });

      test('StopMulticastStreamingResponse', () {
        final envelope = Envelope.fromXmlFile(
          '../../test_data/xml/IPD-H4K8M05-BS/media1/StopMulticastStreamingResponse.xml',
        );

        expect(
          envelope.body.response!.containsKey('StopMulticastStreamingResponse'),
          true,
        );
      });
    });
  });
}
