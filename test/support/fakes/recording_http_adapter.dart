import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Records Dio traffic and returns a scripted body. Tests use this instead of
/// copying an [HttpClientAdapter] into every file.
class RecordingHttpAdapter implements HttpClientAdapter {
  RecordingHttpAdapter({
    this.statusCode = 201,
    this.body =
        '{"id": 1, "number": 1, "title": "Test Issue", "content": {"download_url": "https://raw.github.com/test", "html_url": "https://github.com/test"}}',
    this.error,
  });

  int statusCode;
  String body;
  DioException? error;

  final requests = <RequestOptions>[];
  final requestBodies = <dynamic>[];

  RequestOptions get lastRequestOptions => requests.last;
  dynamic get lastData => requestBodies.last;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    requestBodies.add(options.data);
    if (error != null) throw error!;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
