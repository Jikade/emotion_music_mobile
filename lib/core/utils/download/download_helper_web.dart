import 'dart:html' as html;

Future<void> downloadFromUrl(String url, String fileName) async {
  try {
    final request = await html.HttpRequest.request(url, responseType: 'blob');

    final blob = request.response as html.Blob;
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: blobUrl)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(blobUrl);
  } catch (_) {
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..target = '_blank'
      ..style.display = 'none';

    anchor.setAttribute('rel', 'noopener noreferrer');

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  }
}
