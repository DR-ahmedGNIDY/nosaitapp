import 'dart:html' as html;
import 'dart:typed_data';

import 'package:dio/dio.dart';

// On web, image_picker returns an XFile whose `.path` is a `blob:` URL, not
// a filesystem path — `MultipartFile.fromFile` can't read it. Fetch the blob
// bytes back via XHR (same-page blob URLs are always fetchable) and build the
// multipart from bytes instead.
Future<MultipartFile> buildImageMultipart(
  String pathOrBlobUrl, {
  required String filename,
}) async {
  final request = await html.HttpRequest.request(
    pathOrBlobUrl,
    responseType: 'arraybuffer',
  );
  final bytes = (request.response as ByteBuffer).asUint8List();
  return MultipartFile.fromBytes(bytes, filename: filename);
}
