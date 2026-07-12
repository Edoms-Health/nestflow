class LabelModel {
  final int id;
  final String name;
  final String color;

  const LabelModel({
    required this.id,
    required this.name,
    required this.color,
  });

  LabelModel copyWith({int? id, String? name, String? color}) {
    return LabelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}
