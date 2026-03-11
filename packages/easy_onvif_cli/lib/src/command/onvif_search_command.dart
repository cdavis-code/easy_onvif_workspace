import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:easy_onvif/recordings.dart';
import 'package:easy_onvif/search.dart';
import 'package:easy_onvif/util.dart';

import 'onvif_helper_command.dart';

class OnvifSearchCommand extends Command {
  @override
  String get description => 'Search commands.';

  @override
  String get name => 'search';

  OnvifSearchCommand() {
    addSubcommand(OnvifGetRecordingInformationSearchCommand());
    addSubcommand(OnvifGetRecordingSearchResultsSearchCommand());
    addSubcommand(OnvifGetRecordingSummarySearchCommand());
    addSubcommand(OnvifFindRecordingsSearchCommand());
  }
}

/// Returns information about a single Recording specified by a RecordingToken.
/// This operation is mandatory to support for a device implementing the
/// recording search service.
class OnvifGetRecordingInformationSearchCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'Returns information about a single Recording specified by a RecordingToken.';

  @override
  String get name => 'get-recording-information';

  OnvifGetRecordingInformationSearchCommand() {
    argParser.addOption(
      'recording-token',
      abbr: 't',
      valueHelp: 'token',
      mandatory: true,
    );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final recordingInformation = await search.getRecordingInformation(
        argResults!['recording-token'],
      );

      print(recordingInformation);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// GetRecordingSearchResults acquires the results from a recording search
/// session previously initiated by a FindRecordings operation. The response
/// shall not include results already returned in previous requests for the same
/// session. If MaxResults is specified, the response shall not contain more
/// than MaxResults results. The number of results relates to the number of
/// recordings. For viewing individual recorded data for a signal track use the
/// FindEvents method.
///
/// GetRecordingSearchResults shall block until:
/// - MaxResults results are available for the response if MaxResults is
/// specified.
/// - MinResults results are available for the response if MinResults is
/// specified.
/// - WaitTime has expired.
/// - Search is completed or stopped.
/// This operation is mandatory to support for a device implementing the
/// recording search service.
class OnvifGetRecordingSearchResultsSearchCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'get-recording-search-results acquires the results from a recording search session previously initiated by a FindRecordings operation.';

  @override
  String get name => 'get-recording-search-results';

  OnvifGetRecordingSearchResultsSearchCommand() {
    argParser
      ..addOption(
        'search-token',
        abbr: 't',
        valueHelp: 'token',
        mandatory: true,
        help: 'The search session to get results from.',
      )
      ..addOption(
        'min-results',
        valueHelp: 'int',
        help: 'The minimum number of results to return in one response.',
      )
      ..addOption(
        'max-results',
        valueHelp: 'int',
        help: 'The maximum number of results to return in one response.',
      )
      ..addOption(
        'wait-time',
        valueHelp: 'duration',
        help:
            'The maximum time before responding to the request, even if the MinResults parameter is not fulfilled.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    try {
      final findRecordingResults = await search.getRecordingSearchResults(
        argResults!['search-token'],
        minResults: argResults?['min-results'],
        maxResults: argResults?['max-results'],
        waitTime: argResults?['wait-time'],
      );

      print(findRecordingResults);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// GetRecordingSummary is used to get a summary description of all recorded
/// data. This operation is mandatory to support for a device implementing the
/// recording search service.
class OnvifGetRecordingSummarySearchCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'get-recording-summary is used to get a summary description of all recorded data.';

  @override
  String get name => 'get-recording-summary';

  @override
  void run() async {
    await initializeOnvif();

    try {
      final recordingSummary = await search.getRecordingSummary();

      print(recordingSummary);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}

/// FindRecordings starts a search session, looking for recordings that matches
/// the scope (See 20.2.4) defined in the request. Results from the search are
/// acquired using the GetRecordingSearchResults request, specifying the search
/// token returned from this request. The device shall continue searching until
/// one of the following occurs:
/// The entire time range from StartPoint to EndPoint has been searched through.
/// The total number of matches has been found, defined by the MaxMatches
/// parameter.
/// The session has been ended by a client EndSession request.
/// The session has been ended because KeepAliveTime since the last request
/// related to this session has expired.
/// The order of the results is undefined, to allow the device to return results
/// in any order they are found. This operation is mandatory to support for a
/// device implementing the recording search service.
class OnvifFindRecordingsSearchCommand extends OnvifHelperCommand {
  @override
  String get description =>
      'find-recordings starts a search session, looking for recordings that matches the scope defined in the request.';

  @override
  String get name => 'find-recordings';

  OnvifFindRecordingsSearchCommand() {
    argParser
      ..addOption('scope-include-sources-type', valueHelp: 'string', help: '')
      ..addOption('scope-include-sources-token', valueHelp: 'string', help: '')
      ..addOption(
        'scope-include-recordings',
        valueHelp: 'string',
        help:
            'A list of recordings that are included in the scope. If this list is included, only data from one of these recordings shall be searched.',
      )
      ..addOption(
        'scope-recording-information-filter',
        valueHelp: 'string',
        help:
            'An xpath expression used to specify what recordings to search. Only those recordings with an RecordingInformation structure that matches the filter shall be searched.',
      )
      ..addOption(
        'max-matches',
        valueHelp: 'int',
        help:
            'The search will be completed after this many matches. If not specified, the search will continue until reaching the endpoint or until the session expires.',
      )
      ..addOption(
        'keep-alive-time',
        valueHelp: 'duration',
        defaultsTo: 'PT0S',
        help:
            'The time the search session will be kept alive after responding to this and subsequent requests. A device shall support at least values up to ten seconds.',
      );
  }

  @override
  void run() async {
    await initializeOnvif();

    final needsSourceToken =
        (argResults?['scope-include-sources-type'] ??
            argResults?['scope-include-sources-token']) !=
        null;

    final sourceToken = needsSourceToken
        ? [
            SourceToken(
              type: argResults?['scope-include-sources-type'],
              token: argResults?['scope-include-sources-token'],
            ),
          ]
        : null;

    final needsSearchScope =
        (sourceToken ??
            argResults?['scope-include-recordings'] ??
            argResults?['scope-recording-information-filter']) !=
        null;

    final searchScope = needsSearchScope
        ? SearchScope(
            includedSources: sourceToken,
            includedRecordings: argResults?['scope-include-recordings']
                .toString()
                .split(','),
            recordingInformationFilter:
                argResults?['scope-recording-information-filter'],
          )
        : null;

    try {
      final searchToken = await search.findRecordings(
        searchScope: searchScope,
        maxMatches: argResults?['max-matches'],
        keepAliveTime: argResults!['keep-alive-time'],
      );

      print(searchToken);
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}
