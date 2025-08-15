import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'services/storage_service.dart';

enum ViewMode { mindmap, text }

class AppState extends ChangeNotifier {
  Project _project = Project.empty();
  ViewMode _viewMode = ViewMode.mindmap;
  final Set<String> _selectedTagIds = {};
  String? _selectedNodeId;
  String? _currentFilePath; // nơi đã lưu file
  Timer? _autosaveTimer;

  Project get project => _project;
  ViewMode get viewMode => _viewMode;
  Set<String> get selectedTagIds => _selectedTagIds;
  String? get selectedNodeId => _selectedNodeId;
  String? get currentFilePath => _currentFilePath;

  // ====== VIEW MODE ======
  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  // ====== TAGS ======
  List<Tag> get allTags => _project.tags;
  void addTag(String name, {Color? color}) {
    final id = const Uuid().v4();
    final c = color?.value ?? _randomPastel().value;
    _project.tags.add(Tag(id: id, name: name, color: c));
    _scheduleAutosave();
    notifyListeners();
  }

  void removeTag(String tagId) {
    _project.tags.removeWhere((t) => t.id == tagId);
    // Xoá tag khỏi node
    for (final n in _project.nodes.values) {
      n.tagIds.remove(tagId);
    }
    _selectedTagIds.remove(tagId);
    _scheduleAutosave();
    notifyListeners();
  }

  void renameTag(String tagId, String newName) {
    final t = _project.tags.firstWhere((e) => e.id == tagId);
    t.name = newName;
    _scheduleAutosave();
    notifyListeners();
  }

  void toggleFilterTag(String tagId) {
    if (_selectedTagIds.contains(tagId)) {
      _selectedTagIds.remove(tagId);
    } else {
      _selectedTagIds.add(tagId);
    }
    notifyListeners();
  }

  void clearFilter() {
    _selectedTagIds.clear();
    notifyListeners();
  }

  // ====== NODES ======
  List<MindNode> get allNodes => _project.nodes.values.toList();

  List<MindNode> get filteredNodes {
    if (_selectedTagIds.isEmpty) return allNodes;
    // Lọc AND: node phải chứa tất cả tag đã chọn
    return allNodes
        .where((n) => _selectedTagIds.every((t) => n.tagIds.contains(t)))
        .toList();
  }

  MindNode? nodeById(String id) => _project.nodes[id];

  void selectNode(String? id) {
    _selectedNodeId = id;
    notifyListeners();
  }

  void addNode({String? parentId}) {
    final id = const Uuid().v4();
    final node = MindNode(
      id: id,
      title: 'Node mới',
      position: const Offset(100, 100),
    );
    _project.nodes[id] = node;

    if (parentId != null && _project.nodes.containsKey(parentId)) {
      _project.nodes[parentId]!.children.add(id);
      node.position =
          _project.nodes[parentId]!.position + const Offset(180, 0);
      _project.rootId ??= parentId; // có root nếu cần
    } else {
      // nếu chưa có root, đặt node đầu làm root
      _project.rootId ??= id;
    }
    _scheduleAutosave();
    notifyListeners();
  }

  void updateNodeTitle(String id, String title) {
    final n = _project.nodes[id];
    if (n == null) return;
    n.title = title;
    _scheduleAutosave();
    notifyListeners();
  }

  void setNodeAttributes(String id, List<String> attrs) {
    final n = _project.nodes[id];
    if (n == null) return;
    n.attributes = attrs;
    _scheduleAutosave();
    notifyListeners();
  }

  void setNodeTags(String id, List<String> tagIds) {
    final n = _project.nodes[id];
    if (n == null) return;
    n.tagIds = tagIds;
    _scheduleAutosave();
    notifyListeners();
  }

  void updateNodePosition(String id, Offset pos) {
    final n = _project.nodes[id];
    if (n == null) return;
    n.position = pos;
    notifyListeners(); // kéo thả nhiều → không autosave mỗi pixel
  }

  void deleteNode(String id) {
    // bỏ id khỏi children các node khác
    for (final n in _project.nodes.values) {
      n.children.remove(id);
    }
    _project.nodes.remove(id);
    if (_selectedNodeId == id) _selectedNodeId = null;
    _scheduleAutosave();
    notifyListeners();
  }

  // ====== FILE I/O ======
  Future<void> newProject() async {
    _project = Project.empty();
    _currentFilePath = null;
    _selectedNodeId = null;
    _selectedTagIds.clear();
    notifyListeners();
  }

  Future<void> openProject() async {
    final path = await StorageService.pickOpenPath();
    if (path == null) return;
    final jsonMap = await StorageService.readJson(path);
    _project = Project.fromJson(jsonMap);
    _currentFilePath = path;
    _selectedNodeId = null;
    _selectedTagIds.clear();
    notifyListeners();
  }

  Future<void> saveProject({bool saveAs = false}) async {
    String? path = _currentFilePath;
    if (saveAs || path == null) {
      path = await StorageService.pickSavePath(suggestedName: _project.projectName);
      if (path == null) return;
      if (!path.toLowerCase().endsWith('.json')) {
        path = '$path.json';
      }
      _currentFilePath = path;
    }
    await StorageService.writeJson(path!, _project.toJson());
  }

  // ====== AUTOSAVE (đơn giản) ======
  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () async {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/mindmap_autosave.json';
      await StorageService.writeJson(filePath, _project.toJson());
    });
  }

  // ====== UTILS ======
  Color _randomPastel() {
    final rnd = Random();
    final r = 150 + rnd.nextInt(105);
    final g = 150 + rnd.nextInt(105);
    final b = 150 + rnd.nextInt(105);
    return Color.fromARGB(255, r, g, b);
  }
}
