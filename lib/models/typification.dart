class Typification {
  final String id;
  final String name;
  final String logic;
  final List<String> recommendedTemplateNames;

  const Typification({
    required this.id,
    required this.name,
    required this.logic,
    required this.recommendedTemplateNames,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Typification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
