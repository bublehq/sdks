import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'file_upload_path_stub.dart'
    if (dart.library.io) 'file_upload_path_io.dart' as path_upload;
import 'http_client.dart';
import 'types.dart';

final class FileUpload {
  const FileUpload._({
    required this.filename,
    required this.contentType,
    this.bytes,
    this.stream,
    this.length,
    this.path,
  });

  factory FileUpload.fromBytes(
    List<int> bytes, {
    required String filename,
    String contentType = 'application/octet-stream',
  }) {
    return FileUpload._(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      length: bytes.length,
    );
  }

  factory FileUpload.fromStream(
    Stream<List<int>> stream, {
    required int length,
    required String filename,
    String contentType = 'application/octet-stream',
  }) {
    return FileUpload._(
      stream: stream,
      length: length,
      filename: filename,
      contentType: contentType,
    );
  }

  factory FileUpload.fromPath(
    String path, {
    String? filename,
    String? contentType,
  }) {
    final resolvedFilename = filename ?? path_upload.basename(path);
    return FileUpload._(
      path: path,
      filename: resolvedFilename,
      contentType: contentType ?? inferContentType(resolvedFilename),
    );
  }

  final List<int>? bytes;
  final Stream<List<int>>? stream;
  final int? length;
  final String? path;
  final String filename;
  final String contentType;

  Future<http.MultipartFile> toMultipartFile() async {
    if (path != null) {
      return path_upload.multipartFileFromPath(
        path!,
        filename: filename,
        contentType: contentType,
      );
    }
    if (bytes != null) {
      return http.MultipartFile.fromBytes(
        'file',
        bytes!,
        filename: filename,
        contentType: MediaType.parse(contentType),
      );
    }
    return http.MultipartFile(
      'file',
      stream!,
      length!,
      filename: filename,
      contentType: MediaType.parse(contentType),
    );
  }
}

final class UploadOptions {
  const UploadOptions({this.fileType, this.model, this.mode});

  final String? fileType;
  final String? model;
  final String? mode;

  Map<String, String> toFields() {
    return {
      if (fileType != null && fileType!.isNotEmpty) 'file_type': fileType!,
      if (model != null && model!.isNotEmpty) 'model': model!,
      if (mode != null && mode!.isNotEmpty) 'mode': mode!,
    };
  }
}

final class FilesResource {
  const FilesResource(this._http);

  final BubleHttpClient _http;

  Future<Envelope<UploadedFile>> upload(
    FileUpload file, {
    UploadOptions options = const UploadOptions(),
  }) async {
    final request = http.MultipartRequest('POST', _http.url('/api/v1/files'));
    request.fields.addAll(options.toFields());
    request.files.add(await file.toMultipartFile());
    return _http.sendMultipart(
      request,
      decoder: (json) =>
          Envelope(data: UploadedFile.fromJson(asJsonMap(json['data']))),
    );
  }
}

String inferContentType(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    _ => 'application/octet-stream',
  };
}
