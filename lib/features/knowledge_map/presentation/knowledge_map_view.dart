import 'package:flutter/material.dart';

import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/models/concept_status.dart';
import '../application/knowledge_map_layout.dart';
import 'knowledge_graph_painter.dart';

/// Tampilan graf pengetahuan yang bisa dizoom dan digeser.
///
/// Kanvas [KnowledgeMapLayout] dirender [KnowledgeGraphPainter] di dalam
/// [InteractiveViewer]. Ketukan dipetakan ke koordinat kanvas lewat
/// `RenderBox.globalToLocal` pada kotak kanvas sehingga hit-testing node
/// tetap akurat pada semua tingkat zoom dan geseran.
class KnowledgeMapView extends StatefulWidget {
  /// Graf prasyarat antar-konsep.
  final KnowledgeGraph graph;

  /// Status tiap id konsep.
  final Map<String, ConceptStatus> statuses;

  /// Dipanggil dengan id konsep saat node diketuk.
  final ValueChanged<String>? onNodeTap;

  const KnowledgeMapView({
    super.key,
    required this.graph,
    required this.statuses,
    this.onNodeTap,
  });

  @override
  State<KnowledgeMapView> createState() => _KnowledgeMapViewState();
}

class _KnowledgeMapViewState extends State<KnowledgeMapView> {
  late final TransformationController _controller;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details, KnowledgeMapLayout layout) {
    final context = _canvasKey.currentContext;
    if (context == null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final local = box.globalToLocal(details.globalPosition);
    final id = layout.nodeAt(local);
    if (id != null) widget.onNodeTap?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final layout = KnowledgeMapLayout.fromGraph(widget.graph);
    final colors = Theme.of(context).colorScheme;

    return InteractiveViewer(
      transformationController: _controller,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.4,
      maxScale: 3.0,
      constrained: false,
      child: GestureDetector(
        key: const Key('knowledge-map-canvas'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _handleTapUp(details, layout),
        child: SizedBox(
          key: _canvasKey,
          width: layout.size.width,
          height: layout.size.height,
          child: CustomPaint(
            painter: KnowledgeGraphPainter(
              layout: layout,
              graph: widget.graph,
              statuses: widget.statuses,
              activeEdgeColor: colors.primary,
              dimmedEdgeColor: colors.outlineVariant,
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}
