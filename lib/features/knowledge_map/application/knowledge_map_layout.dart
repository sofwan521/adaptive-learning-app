import 'dart:math';
import 'dart:ui';

import '../../../domain/graph/knowledge_graph.dart';

/// Kedalaman tiap konsep: panjang jalur terpanjang dari akar.
///
/// Akar (tanpa prasyarat) berkedalaman 0; konsep lain berkedalaman
/// 1 + maks kedalaman prasyarat langsungnya. Dihitung sekali jalan
/// mengikuti urutan topologis sehingga prasyarat selalu sudah terisi.
Map<String, int> computeKnowledgeDepths(KnowledgeGraph graph) {
  final depths = <String, int>{};
  for (final id in graph.topologicalOrder()) {
    var depth = 0;
    for (final parent in graph.prerequisitesOf(id)) {
      depth = max(depth, (depths[parent] ?? 0) + 1);
    }
    depths[id] = depth;
  }
  return depths;
}

/// Tata letak berlapis peta konsep (geometri logis dalam piksel).
///
/// Tiap lapisan (satu kedalaman) menjadi satu baris horizontal;
/// node dalam satu baris diratakan tengah agar panah prasyarat
/// mengalir rapi dari atas ke bawah. Ukuran kanvas menyesuaikan
/// lapisan terlebar dan jumlah lapisan sehingga 8–20 node tidak
/// tumpang tindih (jarak antar-node selalu >= celah yang ditetapkan).
class KnowledgeMapLayout {
  /// Lebar kartu node.
  static const double nodeWidth = 148;

  /// Tinggi kartu node.
  static const double nodeHeight = 100;

  /// Jarak horizontal antar-node dalam satu lapisan.
  static const double horizontalGap = 28;

  /// Jarak vertikal antar-lapisan.
  static const double verticalGap = 64;

  /// Bantalan tepi kanvas.
  static const double padding = 32;

  /// Kedalaman tiap id konsep.
  final Map<String, int> depths;

  /// Titik tengah tiap node dalam koordinat kanvas.
  final Map<String, Offset> centers;

  /// Kotak batas tiap node dalam koordinat kanvas.
  final Map<String, Rect> rects;

  /// Ukuran total kanvas.
  final Size size;

  const KnowledgeMapLayout({
    required this.depths,
    required this.centers,
    required this.rects,
    required this.size,
  });

  /// Susun tata letak dari [graph].
  ///
  /// Urutan node dalam satu lapisan mengikuti urutan topologis
  /// agar deterministik di semua perangkat.
  factory KnowledgeMapLayout.fromGraph(KnowledgeGraph graph) {
    final depths = computeKnowledgeDepths(graph);
    final order = graph.topologicalOrder();

    final layers = <int, List<String>>{};
    for (final id in order) {
      layers.putIfAbsent(depths[id]!, () => []).add(id);
    }
    final sortedDepths = layers.keys.toList()..sort();

    var widest = 0;
    for (final depth in sortedDepths) {
      widest = max(widest, layers[depth]!.length);
    }
    final totalWidth = widest <= 0
        ? padding * 2
        : widest * (nodeWidth + horizontalGap) -
            horizontalGap +
            padding * 2;
    final totalHeight = sortedDepths.isEmpty
        ? padding * 2
        : sortedDepths.length * (nodeHeight + verticalGap) -
            verticalGap +
            padding * 2;

    final centers = <String, Offset>{};
    final rects = <String, Rect>{};
    for (var row = 0; row < sortedDepths.length; row++) {
      final ids = layers[sortedDepths[row]]!;
      final rowWidth =
          ids.length * (nodeWidth + horizontalGap) - horizontalGap;
      var x = (totalWidth - rowWidth) / 2;
      final y = padding + row * (nodeHeight + verticalGap);
      for (final id in ids) {
        final rect = Rect.fromLTWH(x, y, nodeWidth, nodeHeight);
        rects[id] = rect;
        centers[id] = rect.center;
        x += nodeWidth + horizontalGap;
      }
    }

    return KnowledgeMapLayout(
      depths: depths,
      centers: centers,
      rects: rects,
      size: Size(totalWidth, totalHeight),
    );
  }

  /// Id node pada titik kanvas [point], atau null bila tak ada.
  ///
  /// Dipakai setelah koordinat viewport diubah ke koordinat kanvas
  /// lewat `TransformationController.toScene`.
  String? nodeAt(Offset point) {
    for (final entry in rects.entries) {
      if (entry.value.contains(point)) return entry.key;
    }
    return null;
  }
}
