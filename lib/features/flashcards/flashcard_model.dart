class Flashcard {
  final String id;

  /// front = PL, back = EN
  final String front;
  final String back;

  /// Lokalna ścieżka do pliku (z image_picker)
  final String? imagePath;

  /// null = fiszka bez folderu
  final String? folderId;

  final int createdAt;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.createdAt,
    this.imagePath,
    this.folderId,
  });

  static const Object _noChange = Object();

  Flashcard copyWith({
    String? id,
    String? front,
    String? back,
    Object? imagePath = _noChange,
    Object? folderId = _noChange, // null = usuń przypisanie do folderu
    int? createdAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      imagePath: identical(imagePath, _noChange) ? this.imagePath : imagePath as String?,
      folderId: identical(folderId, _noChange) ? this.folderId : folderId as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'front': front,
        'back': back,
        'imagePath': imagePath,
        'folderId': folderId,
        'createdAt': createdAt,
      };

  factory Flashcard.fromMap(Map<String, dynamic> map) => Flashcard(
        id: map['id'] as String,
        front: map['front'] as String,
        back: map['back'] as String,
        imagePath: map['imagePath'] as String?,
        folderId: map['folderId'] as String?,
        createdAt: map['createdAt'] as int,
      );
}