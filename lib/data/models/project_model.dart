class ProjectModel {
  final int id;
  final String name;
  final String color;
  final int sortOrder;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.color,
    required this.sortOrder,
    required this.createdAt,
  });

  ProjectModel copyWith({
    int? id,
    String? name,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
