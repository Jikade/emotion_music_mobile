import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/music_downloader.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/music/models/track.dart';
import '../../features/music/providers/music_providers.dart';
import '../../features/payments/presentation/vip_pro_payment_sheet.dart';

class DownloadTrackButton extends ConsumerStatefulWidget {
  const DownloadTrackButton({
    super.key,
    required this.track,
    this.showLabel = false,
    this.compact = false,
  });

  final Track track;
  final bool showLabel;
  final bool compact;

  @override
  ConsumerState<DownloadTrackButton> createState() =>
      _DownloadTrackButtonState();
}

class _DownloadTrackButtonState extends ConsumerState<DownloadTrackButton> {
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    final authState = ref.read(authControllerProvider);
    final user = authState.user;

    if (user == null || user.isVip != true) {
      _showNeedVipMessage();
      return;
    }

    final apiClient = ref.read(apiClientProvider);
    final audioUrl = apiClient.mediaUrl(widget.track.audioUrl);

    if (audioUrl.trim().isEmpty) {
      _showMessage('Bài hát này chưa có file audio để tải.');
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final fileName = _buildFileName(widget.track, audioUrl);

      await downloadMusicFile(url: audioUrl, fileName: fileName);

      if (!mounted) return;

      _showMessage('Đang tải bài hát về máy...');
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showNeedVipMessage() {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff111827),
        content: const Text(
          'Hãy mua gói vip pro để có thể tải các bài hát',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        action: SnackBarAction(
          label: 'Mua VIP PRO',
          textColor: const Color(0xffffd166),
          onPressed: () {
            showVipProPaymentSheet(context);
          },
        ),
      ),
    );
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff111827),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _buildFileName(Track track, String audioUrl) {
    final title = _sanitizeFilePart(track.title);
    final artist = _sanitizeFilePart(track.artist);

    final uri = Uri.tryParse(audioUrl);
    final path = uri?.path ?? '';
    final ext = _readExtension(path);

    final baseName = [
      if (title.isNotEmpty) title,
      if (artist.isNotEmpty) artist,
    ].join(' - ');

    if (baseName.isEmpty) {
      return 'moodsync-track.$ext';
    }

    return '$baseName.$ext';
  }

  String _sanitizeFilePart(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _readExtension(String path) {
    final lastSegment = path
        .split('/')
        .where((item) => item.isNotEmpty)
        .lastOrNull;

    if (lastSegment == null || !lastSegment.contains('.')) {
      return 'mp3';
    }

    final ext = lastSegment.split('.').last.toLowerCase();

    if (ext.length < 2 || ext.length > 5) {
      return 'mp3';
    }

    return ext;
  }

  @override
  Widget build(BuildContext context) {
    final isVip = ref.watch(authControllerProvider).user?.isVip == true;

    final icon = _isDownloading
        ? SizedBox(
            width: widget.compact ? 16 : 18,
            height: widget.compact ? 16 : 18,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Icon(
            isVip ? Icons.download_rounded : Icons.lock_rounded,
            size: widget.compact ? 19 : 21,
          );

    if (widget.showLabel) {
      return FilledButton.icon(
        onPressed: _isDownloading ? null : _handleDownload,
        style: FilledButton.styleFrom(
          backgroundColor: isVip
              ? const Color(0xff22d3ee)
              : const Color(0xffffd166),
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white.withOpacity(0.12),
          disabledForegroundColor: Colors.white.withOpacity(0.42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: icon,
        label: Text(
          isVip ? 'Tải nhạc' : 'Cần VIP PRO',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return Tooltip(
      message: isVip ? 'Tải nhạc' : 'Cần VIP PRO để tải nhạc',
      child: IconButton(
        onPressed: _isDownloading ? null : _handleDownload,
        style: IconButton.styleFrom(
          backgroundColor: isVip
              ? const Color(0xff22d3ee).withOpacity(0.13)
              : const Color(0xffffd166).withOpacity(0.13),
          foregroundColor: isVip
              ? const Color(0xffa5f3fc)
              : const Color(0xffffd166),
          disabledForegroundColor: Colors.white.withOpacity(0.38),
          fixedSize: Size(widget.compact ? 38 : 42, widget.compact ? 38 : 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 14 : 16),
            side: BorderSide(
              color: isVip
                  ? const Color(0xff22d3ee).withOpacity(0.24)
                  : const Color(0xffffd166).withOpacity(0.24),
            ),
          ),
        ),
        icon: icon,
      ),
    );
  }
}
