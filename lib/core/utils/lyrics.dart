class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});
}

List<LyricLine> parseLyrics(String? rawLyrics) {
  if (rawLyrics == null || rawLyrics.trim().isEmpty) {
    return const [];
  }

  final lines = rawLyrics
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final timedLyrics = <LyricLine>[];

  // Hỗ trợ cả:
  // 01:20 lyric
  // [01:20] lyric
  // [01:20.50] lyric
  final regex = RegExp(r'^\[?(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]?\s*(.*)$');

  for (final line in lines) {
    final match = regex.firstMatch(line);

    if (match == null) continue;

    final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;

    if (seconds > 59) continue;

    final fractionRaw = match.group(3) ?? '0';

    var text = match.group(4)?.trim() ?? '';
    text = text
        .replaceFirst(RegExp(r'^♪\s*'), '')
        .replaceFirst(RegExp(r'\s*♪$'), '')
        .trim();

    if (text.isEmpty) continue;

    int milliseconds = 0;

    if (fractionRaw.length == 1) {
      milliseconds = int.parse(fractionRaw) * 100;
    } else if (fractionRaw.length == 2) {
      milliseconds = int.parse(fractionRaw) * 10;
    } else {
      milliseconds = int.parse(fractionRaw.padRight(3, '0').substring(0, 3));
    }

    timedLyrics.add(
      LyricLine(
        time: Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        ),
        text: text,
      ),
    );
  }

  timedLyrics.sort((a, b) => a.time.compareTo(b.time));

  if (timedLyrics.isNotEmpty) {
    return timedLyrics;
  }

  // Fallback: nếu lyrics trong DB chỉ là text thường, vẫn cho hiện từng dòng.
  // Mỗi dòng cách nhau 4 giây.
  return lines.asMap().entries.map((entry) {
    return LyricLine(
      time: Duration(seconds: entry.key * 4),
      text: entry.value,
    );
  }).toList();
}

LyricLine? getCurrentLyricLine(List<LyricLine> lyrics, Duration currentTime) {
  if (lyrics.isEmpty) return null;

  var left = 0;
  var right = lyrics.length - 1;
  LyricLine? result;

  while (left <= right) {
    final middle = (left + right) ~/ 2;

    if (lyrics[middle].time <= currentTime) {
      result = lyrics[middle];
      left = middle + 1;
    } else {
      right = middle - 1;
    }
  }

  return result;
}
