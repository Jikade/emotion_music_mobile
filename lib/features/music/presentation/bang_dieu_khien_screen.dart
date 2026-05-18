import 'package:flutter/material.dart';

import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/song_grid.dart';

class BangDieuKhienScreen extends StatelessWidget {
  const BangDieuKhienScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Bảng điều khiển',
          title: 'Không gian nghe của cậu',
          description:
              'Dùng thanh lọc bên trên để tìm bài hát, lọc theo mood hoặc chỉ xem các bài đã like.',
        ),
        Expanded(
          child: SongGrid(
            emptyMessage: 'Không có bài hát nào phù hợp với bộ lọc hiện tại.',
          ),
        ),
      ],
    );
  }
}
