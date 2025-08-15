import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import 'package:provider/provider.dart';

class MindmapView extends StatelessWidget {
  const MindmapView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nodes = state.filteredNodes;
    final selectedId = state.selectedNodeId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => state.selectNode(null),
      child: Stack(
        children: [
          // Edges layer
          CustomPaint(
            painter: _EdgesPainter(
              nodesMap: {for (final n in nodes) n.id: n},
            ),
            size: Size.infinite,
          ),
          // Nodes layer
          ...nodes.map((n) => _DraggableNode(
                node: n,
                selected: n.id == selectedId,
              )),
        ],
      ),
    );
  }
}

class _DraggableNode extends StatelessWidget {
  final MindNode node;
  final bool selected;
  const _DraggableNode({required this.node, required this.selected});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final tags = state.project.tags
        .where((t) => node.tagIds.contains(t.id))
        .toList();

    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: GestureDetector(
        onTap: () => state.selectNode(node.id),
        onDoubleTap: () => _openEditDialog(context, node.id),
        onPanUpdate: (d) =>
            state.updateNodePosition(node.id, node.position + d.delta),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: selected ? Colors.blue.withOpacity(0.4) : Colors.black12,
                blurRadius: selected ? 12 : 6,
                spreadRadius: selected ? 2 : 1,
              )
            ],
            border: Border.all(
              color: selected ? Colors.blue : Colors.black12,
              width: selected ? 2 : 1,
            ),
          ),
          constraints: const BoxConstraints(minWidth: 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(node.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.blue : Colors.black87)),
              const SizedBox(height: 6),
              ...node.attributes.take(3).map((a) => Text('• $a',
                  style: const TextStyle(fontSize: 12, color: Colors.black54))),
              if (node.attributes.length > 3)
                Text('(+${node.attributes.length - 3} đặc điểm)',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black38)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: -8,
                children: [
                  for (final t in tags)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(t.color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(t.color).withOpacity(0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, String nodeId) async {
    await showDialog(
      context: context,
      builder: (_) => _EditNodeDialog(nodeId: nodeId),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  final Map<String, MindNode> nodesMap;
  _EdgesPainter({required this.nodesMap});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final n in nodesMap.values) {
      for (final childId in n.children) {
        final child = nodesMap[childId];
        if (child == null) continue; // child có thể bị ẩn do filter
        final p1 = n.position + const Offset(80, 30);
        final p2 = child.position + const Offset(0, 30);

        final cp1 = Offset((p1.dx + p2.dx) / 2, p1.dy);
        final cp2 = Offset((p1.dx + p2.dx) / 2, p2.dy);

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) =>
      oldDelegate.nodesMap != nodesMap;
}

class _EditNodeDialog extends StatefulWidget {
  final String nodeId;
  const _EditNodeDialog({required this.nodeId});

  @override
  State<_EditNodeDialog> createState() => _EditNodeDialogState();
}

class _EditNodeDialogState extends State<_EditNodeDialog> {
  late TextEditingController _titleCtl;
  late TextEditingController _attrsCtl;
  late List<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final n = state.nodeById(widget.nodeId)!;
    _titleCtl = TextEditingController(text: n.title);
    _attrsCtl = TextEditingController(text: n.attributes.join(', '));
    _selectedTagIds = [...n.tagIds];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tags = state.allTags;
    return AlertDialog(
      title: const Text('Chỉnh sửa node'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleCtl,
                decoration: const InputDecoration(labelText: 'Tên'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _attrsCtl,
                decoration: const InputDecoration(
                    labelText: 'Đặc điểm (phân tách bằng dấu phẩy)'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Thẻ (tags)', style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final t in tags)
                    FilterChip(
                      label: Text(t.name),
                      selected: _selectedTagIds.contains(t.id),
                      onSelected: (s) {
                        setState(() {
                          if (s) {
                            _selectedTagIds.add(t.id);
                          } else {
                            _selectedTagIds.remove(t.id);
                          }
                        });
                      },
                    )
                ],
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            state.updateNodeTitle(widget.nodeId, _titleCtl.text.trim());
            final attrs = _attrsCtl.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            state.setNodeAttributes(widget.nodeId, attrs);
            state.setNodeTags(widget.nodeId, _selectedTagIds);
            Navigator.pop(context);
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
