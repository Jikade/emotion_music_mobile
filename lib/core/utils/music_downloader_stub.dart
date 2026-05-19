import 'package:url_launcher/url_launcher.dart';

Future<void> downloadMusicFile({
  required String url,
  required String fileName,
}) async {
  final uri = Uri.tryParse(url);

  if (uri == null) {
    throw Exception('Đường dẫn audio không hợp lệ.');
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!opened) {
    throw Exception('Không thể mở đường dẫn tải nhạc.');
  }
}
