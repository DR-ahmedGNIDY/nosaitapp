import 'package:dio/dio.dart';

Future<MultipartFile> buildImageMultipart(
  String pathOrBlobUrl, {
  required String filename,
}) {
  return MultipartFile.fromFile(pathOrBlobUrl, filename: filename);
}
