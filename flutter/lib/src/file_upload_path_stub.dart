import 'package:http/http.dart' as http;

String basename(String path) => path.split(RegExp(r'[/\\]')).last;

Future<http.MultipartFile> multipartFileFromPath(
  String path, {
  required String filename,
  required String contentType,
}) {
  throw UnsupportedError(
    'FileUpload.fromPath is only available on Dart IO platforms. '
    'Use FileUpload.fromBytes or FileUpload.fromStream instead.',
  );
}
