import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'views/mindmap_view.dart';
import 'views/text_view.dart';
import 'models.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MindmapApp(),
    ),
  );
}

class MindmapApp extends StatelessWidget {
  const MindmapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Mindmap Desktop',
      theme: theme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isMindmap = state.viewMode == ViewMode.mindmap;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.project.projectName),
        actions: [
          IconButton(
            tooltip: 'Tạo dự án mới',
            icon: const Icon(Icons.note_add),
            onPressed: () => state.newProject(),
          ),
          IconButton(
            tooltip: 'Mở file JSON',
            icon: const Icon(Icons.folder_open),
            onPressed: () => state.openProject(),
          ),
          IconButton(
            tooltip: 'Lưu',
            icon: const Icon(Icons.save),
            onPressed: () => state.saveProject(),
          ),
          IconButton(
            tooltip: 'Lưu thành...',
            icon: const Icon(Icons.save_as),
            onPressed: () => state.saveProject(saveAs: true),
          ),
          const SizedBox(width: 12),
          // Toggle view
          ToggleButtons(
            isSelected: [isMindmap, !isMindmap],
            onPressed: (i) {
              state.setViewMode(i == 0 ? ViewMode.mindmap : ViewMode.text);
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.account_tree_rounded),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.view_list_rounded),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Quản lý thẻ',
            icon: const Icon(Icons.sell_outlined),
            onPressed: () => _openTagManager(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          const _FilterBar(),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isMindmap ? const MindmapView() : const TextView(),
            ),
          ),
        ],
      ),
      floatingActionButton: _FabBar(),
    );
  }

  Future<void> _openTagManager(BuildContext context) async {
    final state = context.read<AppState>();
    final nameCtl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Quản lý thẻ', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameCtl,
                        decoration: const InputDecoration(
                          labelText: 'Tên thẻ mới',
                          hintText: 'VD: Công nghệ',
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            state.addTag(v.trim());
                            nameCtl.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final v = nameCtl.text.trim();
                        if (v.isNotEmpty) {
                          state.addTag(v);
                          nameCtl.clear();
                        }
                      },
                      child: const Text('Thêm'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.allTags.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (_, i) {
                      final t = state.allTags[i];
                      final ctl = TextEditingController(text: t.name);
                      return Row(
                        children: [
                          Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              color: Color(t.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: ctl,
                              decoration: const InputDecoration(border: UnderlineInputBorder()),
                              onSubmitted: (v) {
                                if (v.trim().isNotEmpty) {
                                  state.renameTag(t.id, v.trim());
                                }
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Xoá thẻ',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => state.removeTag(t.id),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tags = state.allTags;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text('Lọc theo thẻ:  '),
          Wrap(
            spacing: 8,
            children: [
              for (final t in tags)
                FilterChip(
                  label: Text(t.name),
                  selected: state.selectedTagIds.contains(t.id),
                  onSelected: (_) => state.toggleFilterTag(t.id),
                ),
              if (tags.isEmpty) const Text('(chưa có thẻ)'),
              if (tags.isNotEmpty)
                TextButton(
                  onPressed: () => state.clearFilter(),
                  child: const Text('Bỏ lọc'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selected = state.selectedNodeId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'add_node',
          onPressed: () => state.addNode(),
          label: const Text('Thêm Node'),
          icon: const Icon(Icons.add),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'add_child',
          onPressed: selected == null ? null : () => state.addNode(parentId: selected),
          label: const Text('Thêm Con'),
          icon: const Icon(Icons.subdirectory_arrow_right),
        ),
      ],
    );
  }
}
