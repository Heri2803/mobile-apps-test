// download_web.dart
import 'dart:html' as html;
import 'dart:typed_data';

void downloadFileWeb(Uint8List data, String fileName) {
  final blob = html.Blob([data]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  html.Url.revokeObjectUrl(url);
}
