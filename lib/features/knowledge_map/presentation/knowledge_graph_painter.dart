import 'package:flutter/material.dart';

import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/models/concept.dart';
import '../../../domain/models/concept_status.dart';
import '../application/knowledge_map_layout.dart';
import 'knowledge_map_style.dart';

/// Pelukis graf pengetahuan: edge berpanah lalu kartu node.
///
/// - Edge digambar dari tepi bawah prasyarat ke tepi atas konsep
///   dengan kepala panah; edge menuju node terkunci memakai
///   [dimmedEdgeColor] yang redup.
/// - Node memakai warna dan ikon sesuai statusnya serta label
///   singkat (kode + nama terpotong elipsis).
class KnowledgeGraphPainter extends CustomPainter {
  /// Tata letak geometri kanvas.
  final KnowledgeMapLayout layout;

  /// Graf untuk daftar edge dan data konsep.
  final KnowledgeGraph graph;

  /// Status tiap id konsep (default terkunci bila tak ada).
  final Map<String, ConceptStatus> statuses;

  /// Warna edge biasa (prasyarat -> konsep terbuka).
  final Color activeEdgeColor;

  /// Warna edge redup menuju node terkunci.
  final Color dimmedEdgeColor;

  /// Lebar garis edge.
  final double edgeWidth;

  /// Arah teks untuk [TextPainter].
  final TextDirection textDirection;

  KnowledgeGraphPainter({
    required this.layout,
    required this.graph,
    required this.statuses,
    required this.activeEdgeColor,
    required this.dimmedEdgeColor,
    this.edgeWidth = 2,
    this.textDirection = TextDirection.ltr,
  });

  ConceptStatus _statusOf(String id) =>
      statuses[id] ?? ConceptStatus.locked;

  @override
  void paint(Canvas canvas, Size size) {
    _paintEdges(canvas);
    _paintNodes(canvas);
  }

  void _paintEdges(Canvas canvas) {
    for (final targetId in graph.conceptIds) {
      final target = layout.rects[targetId];
      if (target == null) continue;
      final dimmed = _statusOf(targetId) == ConceptStatus.locked;
      final paint = Paint()
        ..color = dimmed ? dimmedEdgeColor : activeEdgeColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final sourceId in graph.prerequisitesOf(targetId)) {
        final source = layout.rects[sourceId];
        if (source == null) continue;
        _paintArrow(
          canvas,
          Offset(source.center.dx, source.bottom),
          Offset(target.center.dx, target.top),
          paint,
        );
      }
    }
  }

  void _paintArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final direction = to - from;
    final length = direction.distance;
    if (length < 8) return;
    final unit = direction / length;
    // Ujung berhenti tepat di tepi node target.
    const inset = 3.0;
    final tip = to - unit * inset;
    canvas.drawLine(from, tip, paint);
    // Kepala panah: dua sayap pendek dari ujung.
    const headLength = 11.0;
    const halfSpread = 5.0;
    final base = tip - unit * headLength;
    final normal = Offset(-unit.dy, unit.dx);
    canvas.drawLine(tip, base + normal * halfSpread, paint);
    canvas.drawLine(tip, base - normal * halfSpread, paint);
  }

  void _paintNodes(Canvas canvas) {
    for (final id in graph.topologicalOrder()) {
      final rect = layout.rects[id];
      if (rect == null) continue;
      final style = mapStatusStyle(_statusOf(id));
      _paintCard(canvas, rect, style);
      _paintLabel(canvas, rect, style, id);
    }
  }

  void _paintCard(
    Canvas canvas,
    Rect rect,
    KnowledgeMapStatusStyle style,
  ) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(rrect, Paint()..color = style.fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = style.border
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintLabel(
    Canvas canvas,
    Rect rect,
    KnowledgeMapStatusStyle style,
    String id,
  ) {
    Concept concept;
    try {
      concept = graph.concept(id);
    } catch (_) {
      return;
    }
    const iconSize = 26.0;
    const codeSize = 15.0;
    const nameSize = 11.5;
    const gapSmall = 4.0;
    const blockHeight = iconSize + gapSmall + 20 + gapSmall + 16;

    var dy = rect.top + (rect.height - blockHeight) / 2;

    // Ikon status sebagai glif Material.
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(style.icon.codePoint),
        style: TextStyle(
          fontFamily: style.icon.fontFamily,
          package: style.icon.fontPackage,
          fontSize: iconSize,
          color: style.border,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(rect.center.dx - iconPainter.width / 2, dy),
    );
    dy += iconSize + gapSmall;

    // Kode konsep (mis. K01) tebal satu baris.
    final codePainter = TextPainter(
      text: TextSpan(
        text: concept.code.isEmpty ? concept.id : concept.code,
        style: TextStyle(
          fontSize: codeSize,
          fontWeight: FontWeight.w800,
          color: style.border,
        ),
      ),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    codePainter.paint(
      canvas,
      Offset(rect.center.dx - codePainter.width / 2, dy),
    );
    dy += 20 + gapSmall;

    // Nama konsep singkat terpotong elipsis.
    final namePainter = TextPainter(
      text: TextSpan(
        text: concept.name,
        style: TextStyle(fontSize: nameSize, color: style.border),
      ),
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: KnowledgeMapLayout.nodeWidth - 16);
    namePainter.paint(
      canvas,
      Offset(rect.center.dx - namePainter.width / 2, dy),
    );
  }

  @override
  bool shouldRepaint(covariant KnowledgeGraphPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.graph != graph ||
        oldDelegate.statuses != statuses ||
        oldDelegate.activeEdgeColor != activeEdgeColor ||
        oldDelegate.dimmedEdgeColor != dimmedEdgeColor ||
        oldDelegate.edgeWidth != edgeWidth ||
        oldDelegate.textDirection != textDirection;
  }
}
