import 'package:flutter/material.dart';

import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/song_grid.dart';

class ThuVienScreen extends StatelessWidget {
  const ThuVienScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          eyebrow: 'Thư viện',
          title: 'Bài hát đã thích',
          description:
              'Chỉ hiển thị những bài hát bạn đã nhấn thích. Mỗi tài khoản sẽ có danh sách yêu thích riêng.',
        ),
        Expanded(
          child: SongGrid(
            forceLikedOnly: true,
            emptyMessage:
                'Bạn chưa thích bài hát nào. Hãy nhấn tim ở bài hát để thêm vào thư viện.',
          ),
        ),
      ],
    );
  }
}
