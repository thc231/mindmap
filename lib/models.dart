import 'dart:ui';

class Tag {
  final String id;
  String name;
  int color; // ARGB (0xFFRRGGBB)

  Tag({required this.id, required this.name, required this.color});

  factory Tag.fromJson(Map<String, dynamic> j) => Tag(
        id: j['id'] as String,
        name: j['name'] as String,
        color: j['color'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
      };
}

class MindNode {
  final String id;
  String title;
  List<String> attributes; // đặc điểm
  List<String> tagIds; // tham chiếu Tag.id
  List<String> children; // id con
  Offset position; // vị trí trên canvas

  MindNode({
    required this.id,
    required this.title,
    List<String>? attributes,
    List<String>? tagIds,
    List<String>? children,
    Offset? position,
  })  : attributes = attributes ?? [],
        tagIds = tagIds ?? [],
        children = children ?? [],
        position = position ?? const Offset(100, 100);

  factory MindNode.fromJson(Map<String, dynamic> j) => MindNode(
        id: j['id'] as String,
        title: j['title'] as String,
        attributes: (j['attributes'] as List).map((e) => e as String).toList(),
        tagIds: (j['tagIds'] as List).map((e) => e as String).toList(),
        children: (j['children'] as List).map((e) => e as String).toList(),
        position: Offset(
          (j['position']['x'] as num).toDouble(),
          (j['position']['y'] as num).toDouble(),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'attributes': attributes,
        'tagIds': tagIds,
        'children': children,
        'position': {'x': position.dx, 'y': position.dy},
      };
}

class Project {
  String projectName;
  int schemaVersion;
  Map<String, MindNode> nodes; // id -> node
  List<Tag> tags;
  String? rootId; // optional root

  Project({
    required this.projectName,
    required this.nodes,
    required this.tags,
    this.rootId,
    this.schemaVersion = 1,
  });

  factory Project.empty() => Project(
        projectName: 'Dự án mới',
        nodes: {},
        tags: [],
        rootId: null,
      );

  factory Project.fromJson(Map<String, dynamic> j) {
    final nodesList = (j['nodes'] as List).map((e) => MindNode.fromJson(e));
    return Project(
      projectName: j['projectName'] as String,
      schemaVersion: (j['schemaVersion'] ?? 1) as int,
      nodes: {for (final n in nodesList) n.id: n},
      tags: (j['tags'] as List).map((e) => Tag.fromJson(e)).toList(),
      rootId: j['rootId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'schemaVersion': schemaVersion,
        'rootId': rootId,
        'tags': tags.map((e) => e.toJson()).toList(),
        'nodes': nodes.values.map((e) => e.toJson()).toList(),
      };
}
