import 'package:flutter/material.dart';

import '../../../domain/models/concept_status.dart';
import 'knowledge_map_style.dart';

/// Legenda status peta konsep: ikon + warna + label Bahasa Indonesia.
class KnowledgeMapLegend extends StatelessWidget {
  const KnowledgeMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const order = [
      ConceptStatus.locked,
      ConceptStatus.open,
      ConceptStatus.learning,
      ConceptStatus.mastered,
    ];
    return Card(
      key: const Key('knowledge-map-legend'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legenda',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final status in order) _LegendItem(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final ConceptStatus status;

  const _LegendItem({required this.status});

  @override
  Widget build(BuildContext context) {
    final style = mapStatusStyle(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: style.fill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: style.border),
          ),
          child: Icon(style.icon, size: 15, color: style.border),
        ),
        const SizedBox(width: 6),
        Text(status.label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
