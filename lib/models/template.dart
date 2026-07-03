import 'dart:convert';

class Template {
  final String id;
  final String name;
  final String content;
  final bool isSystem;
  final String? createdBy;

  Template({
    required this.id,
    required this.name,
    required this.content,
    this.isSystem = false,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'isSystem': isSystem,
      'createdBy': createdBy,
    };
  }

  factory Template.fromMap(Map<String, dynamic> map) {
    return Template(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      content: map['content'] ?? '',
      isSystem: map['isSystem'] ?? false,
      createdBy: map['createdBy'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Template.fromJson(String source) => Template.fromMap(json.decode(source));
}
