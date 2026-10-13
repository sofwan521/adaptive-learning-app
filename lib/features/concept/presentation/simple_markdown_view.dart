import 'package:flutter/material.dart';

import '../application/simple_markdown.dart';

/// Perender markdown sederhana dari blok [parseSimpleMarkdown].
///
/// Mendukung judul, paragraf tebal/miring, daftar, dan gambar
/// (`![alt](url)`, gagal muat menampilkan ikon pengganti).
class SimpleMarkdownView extends StatelessWidget {
  final String source;

  const SimpleMarkdownView({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final blocks = parseSimpleMarkdown(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks) ...[
          _BlockWidget(block: block),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BlockWidget extends StatelessWidget {
  final MarkdownBlock block;

  const _BlockWidget({required this.block});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    if (block is HeadingBlock) {
      final heading = block as HeadingBlock;
      final style = switch (heading.level) {
        1 => textTheme.headlineSmall,
        2 => textTheme.titleLarge,
        _ => textTheme.titleMedium,
      };
      return Text(
        heading.text,
        style: style?.copyWith(fontWeight: FontWeight.w700),
      );
    }
    if (block is ParagraphBlock) {
      return _InlineText(
        spans: (block as ParagraphBlock).spans,
        style: textTheme.bodyMedium,
      );
    }
    if (block is ListBlock) {
      final list = block as ListBlock;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < list.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      list.ordered ? '${i + 1}.' : '•',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _InlineText(
                      spans: list.items[i],
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    if (block is ImageBlock) {
      final image = block as ImageBlock;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          image.url,
          fit: BoxFit.contain,
          semanticLabel: image.alt,
          errorBuilder: (context, _, __) => Container(
            padding: const EdgeInsets.all(24),
            color: colors.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.broken_image_outlined, color: colors.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    image.alt.isEmpty ? 'Gambar tidak dapat dimuat.' : image.alt,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _InlineText extends StatelessWidget {
  final List<InlineSegment> spans;
  final TextStyle? style;

  const _InlineText({required this.spans, this.style});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final span in spans)
            TextSpan(
              text: span.text,
              style: TextStyle(
                fontWeight:
                    span.bold ? FontWeight.w700 : FontWeight.normal,
                fontStyle:
                    span.italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
        ],
        style: style,
      ),
    );
  }
}
