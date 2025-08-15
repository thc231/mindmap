import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class TextView extends StatelessWidget {
  const TextView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nodes = state.filteredNodes;
    final tagMap = {for (final t in state.allTags) t.id: t};

    if (nodes.isEmpty) {
      return const Center(child: Text('Không có kết quả (theo bộ lọc hiện tại).'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: nodes.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (_, i) {
        final n = nodes[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            if (n.attributes.isNotEmpty)
              ...n.attributes.map((a) => Text('+ $a')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: -8,
              children: [
                for (final id in n.tagIds)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(tagMap[id]?.color ?? 0xFFDDDDDD).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(tagMap[id]?.name ?? 'tag'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
