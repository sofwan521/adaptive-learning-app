import 'package:equatable/equatable.dart';

/// Perender markdown sederhana: judul, paragraf (tebal/miring),
/// daftar, dan gambar. Cukup untuk materi ringkas seed.
///
/// Logika murni — tanpa import Flutter — sehingga mudah diuji.

/// Potongan teks sebaris dengan gaya.
class InlineSegment extends Equatable {
  final String text;
  final bool bold;
  final bool italic;

  const InlineSegment(this.text, {this.bold = false, this.italic = false});

  @override
  List<Object?> get props => [text, bold, italic];
}

/// Satu blok markdown hasil uraian.
sealed class MarkdownBlock extends Equatable {
  const MarkdownBlock();

  @override
  List<Object?> get props => [];
}

/// Judul `#` / `##` / `###` (level dibatasi 1..3).
class HeadingBlock extends MarkdownBlock {
  final int level;
  final String text;

  const HeadingBlock(this.level, this.text);

  @override
  List<Object?> get props => [level, text];
}

/// Paragraf teks biasa dengan gaya sebaris.
class ParagraphBlock extends MarkdownBlock {
  final List<InlineSegment> spans;

  const ParagraphBlock(this.spans);

  /// Teks polos gabungan (untuk uji dan aksesibilitas).
  String get plainText => spans.map((s) => s.text).join();

  @override
  List<Object?> get props => [spans];
}

/// Daftar butir (`- ` atau `1. `); [ordered] untuk bernomor.
class ListBlock extends MarkdownBlock {
  final bool ordered;
  final List<List<InlineSegment>> items;

  const ListBlock(this.items, {this.ordered = false});

  @override
  List<Object?> get props => [ordered, items];
}

/// Gambar `![alt](url)`.
class ImageBlock extends MarkdownBlock {
  final String alt;
  final String url;

  const ImageBlock(this.alt, this.url);

  @override
  List<Object?> get props => [alt, url];
}

/// Uraikan [source] menjadi daftar blok sederhana.
///
/// Baris kosong memisahkan paragraf. Baris tak dikenal diperlakukan
/// sebagai paragraf agar tak ada konten yang hilang.
List<MarkdownBlock> parseSimpleMarkdown(String source) {
  final blocks = <MarkdownBlock>[];
  final paragraphLines = <String>[];
  List<String>? listLines;
  bool listOrdered = false;

  void flushParagraph() {
    if (paragraphLines.isEmpty) return;
    blocks.add(ParagraphBlock(parseInline(paragraphLines.join(' '))));
    paragraphLines.clear();
  }

  void flushList() {
    if (listLines == null) return;
    blocks.add(
      ListBlock(
        [for (final line in listLines!) parseInline(line)],
        ordered: listOrdered,
      ),
    );
    listLines = null;
  }

  for (final rawLine in source.split('\n')) {
    final line = rawLine.trimRight();
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      flushParagraph();
      flushList();
      continue;
    }
    final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
    if (heading != null) {
      flushParagraph();
      flushList();
      blocks.add(
        HeadingBlock(heading.group(1)!.length, heading.group(2)!.trim()),
      );
      continue;
    }
    final image =
        RegExp(r'^!\[([^\]]*)\]\(([^)]+)\)$').firstMatch(trimmed);
    if (image != null) {
      flushParagraph();
      flushList();
      blocks.add(ImageBlock(image.group(1)!, image.group(2)!.trim()));
      continue;
    }
    final bullet = RegExp(r'^[-*]\s+(.*)$').firstMatch(trimmed);
    if (bullet != null) {
      flushParagraph();
      if (listLines == null || listOrdered) {
        flushList();
        listLines = [];
        listOrdered = false;
      }
      listLines!.add(bullet.group(1)!);
      continue;
    }
    final numbered = RegExp(r'^\d+[.)]\s+(.*)$').firstMatch(trimmed);
    if (numbered != null) {
      flushParagraph();
      if (listLines == null || !listOrdered) {
        flushList();
        listLines = [];
        listOrdered = true;
      }
      listLines!.add(numbered.group(1)!);
      continue;
    }
    flushList();
    paragraphLines.add(trimmed);
  }
  flushParagraph();
  flushList();
  return blocks;
}

/// Uraikan gaya sebaris `**tebal**` dan `*miring*`.
///
/// Penanda tak berpasangan dibiarkan sebagai teks biasa.
List<InlineSegment> parseInline(String source) {
  final spans = <InlineSegment>[];
  final buffer = StringBuffer();
  var bold = false;
  var italic = false;

  void flush() {
    if (buffer.isEmpty) return;
    spans.add(InlineSegment(buffer.toString(), bold: bold, italic: italic));
    buffer.clear();
  }

  var i = 0;
  while (i < source.length) {
    if (source.startsWith('**', i)) {
      final closing = source.indexOf('**', i + 2);
      if (closing == -1) {
        buffer.write(source.substring(i));
        break;
      }
      flush();
      // Segmen tebal diambil utuh agar tak perlu pelacakan status.
      final inner = source.substring(i + 2, closing);
      if (inner.isNotEmpty) {
        spans.add(InlineSegment(inner, bold: true, italic: italic));
      }
      i = closing + 2;
      continue;
    }
    if (source[i] == '*') {
      final closing = source.indexOf('*', i + 1);
      if (closing == -1) {
        buffer.write(source.substring(i));
        break;
      }
      flush();
      final inner = source.substring(i + 1, closing);
      if (inner.isNotEmpty) {
        spans.add(InlineSegment(inner, bold: bold, italic: true));
      }
      i = closing + 1;
      continue;
    }
    buffer.write(source[i]);
    i++;
  }
  flush();
  return spans;
}
