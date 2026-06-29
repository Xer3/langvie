class FlashFolder {
  final String id;
  final String name;
  final int createdAt;

  const FlashFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  FlashFolder copyWith({String? name}) {
    return FlashFolder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
      };

  factory FlashFolder.fromMap(Map<String, dynamic> map) => FlashFolder(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: map['createdAt'] as int,
      );
}