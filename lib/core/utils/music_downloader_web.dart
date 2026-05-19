import 'dart:html' as html;

Future<void> downloadMusicFile({
  required String url,
  required String fileName,
}) async {
  final request = await html.HttpRequest.request(url, responseType: 'blob');

  final response = request.response;

  if (response is! html.Blob) {
    throw Exception('Không tải được file audio.');
  }

  final objectUrl = html.Url.createObjectUrlFromBlob(response);

  final anchor = html.AnchorElement(href: objectUrl)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(objectUrl);
}
