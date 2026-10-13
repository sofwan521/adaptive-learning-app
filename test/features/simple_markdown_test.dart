import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/features/concept/application/simple_markdown.dart';

void main() {
  group('parseSimpleMarkdown', () {
    test('judul 1-3 dikenali sesuai level', () {
      final blocks = parseSimpleMarkdown(
        '# Bilangan Bulat\n## Aturan tanda\n### Contoh',
      );

      expect(
        blocks,
        [
          const HeadingBlock(1, 'Bilangan Bulat'),
          const HeadingBlock(2, 'Aturan tanda'),
          const HeadingBlock(3, 'Contoh'),
        ],
      );
    });

    test('paragraf multiline digabung dengan spasi', () {
      final blocks = parseSimpleMarkdown(
        'Bilangan bulat terdiri dari\nbilangan negatif, nol, dan positif.',
      );

      expect(blocks, hasLength(1));
      final paragraph = blocks.single as ParagraphBlock;
      expect(
        paragraph.plainText,
        'Bilangan bulat terdiri dari bilangan negatif, nol, dan positif.',
      );
    });

    test('gaya tebal dan miring diuraikan sebaris', () {
      final spans = parseInline('Hitung **-8 + 15** lalu *periksa* lagi.');

      expect(
        spans,
        [
          const InlineSegment('Hitung '),
          const InlineSegment('-8 + 15', bold: true),
          const InlineSegment(' lalu '),
          const InlineSegment('periksa', italic: true),
          const InlineSegment(' lagi.'),
        ],
      );
    });

    test('penanda tak berpasangan dibiarkan sebagai teks', () {
      final spans = parseInline('5 - (-2) = 7 **buka');

      expect(
        spans.map((s) => s.text).join(),
        '5 - (-2) = 7 **buka',
      );
      expect(spans.every((s) => !s.bold), isTrue);
    });

    test('daftar bullet dan bernomor dipisah per jenis', () {
      final blocks = parseSimpleMarkdown(
        '- Tambah atau kurang.\n- Kali atau bagi.\n\n1. Eliminasi.\n2. Substitusi.',
      );

      expect(blocks, hasLength(2));
      final bullets = blocks[0] as ListBlock;
      final numbered = blocks[1] as ListBlock;
      expect(bullets.ordered, isFalse);
      expect(numbered.ordered, isTrue);
      expect(bullets.items, hasLength(2));
      expect(numbered.items.first.single.text, 'Eliminasi.');
    });

    test('gambar memakai sintaks ![alt](url)', () {
      final blocks = parseSimpleMarkdown(
        '![Garis bilangan](https://contoh.id/garis.png)',
      );

      expect(
        blocks,
        [
          const ImageBlock(
            'Garis bilangan',
            'https://contoh.id/garis.png',
          ),
        ],
      );
    });

    test('materi seed: judul, daftar, contoh terurai semua', () {
      const seed = '## Bilangan Bulat\n'
          'Bilangan bulat terdiri dari bilangan negatif, nol, dan positif.\n'
          '\n'
          '### Aturan tanda\n'
          '- Positif tambah positif hasilnya positif.\n'
          '- Negatif dikali negatif hasilnya positif.\n'
          '\n'
          '### Contoh\n'
          'Hitung -8 + 15.\n'
          'Jawab: 15 - 8 = 7.';
      final blocks = parseSimpleMarkdown(seed);

      expect(blocks.whereType<HeadingBlock>(), hasLength(3));
      expect(blocks.whereType<ListBlock>().single.items, hasLength(2));
      // Dua baris contoh tanpa baris kosong menjadi satu paragraf.
      expect(blocks.whereType<ParagraphBlock>(), hasLength(2));
    });

    test('masukan kosong menghasilkan daftar kosong', () {
      expect(parseSimpleMarkdown(''), isEmpty);
      expect(parseSimpleMarkdown('\n\n'), isEmpty);
    });
  });
}
