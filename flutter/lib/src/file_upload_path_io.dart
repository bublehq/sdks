import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

String basename(String path) => path.split(RegExp(r'[/\\]')).last;

Future<http.MultipartFile> multipartFileFromPath(
  String path, {
  required String filename,
  required String contentType,
}) {
  return http.MultipartFile.fromPath(
    'file',
    path,
    filename: filename,
    contentType: MediaType.parse(contentType),
  );
}
