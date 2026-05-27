String encodePathSegment(String value) => Uri.encodeComponent(value);

String encodeModelPath(String value) {
  return value.split('/').map(Uri.encodeComponent).join('/');
}
