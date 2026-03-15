class Medal {
  const Medal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isUnlocked,
    required this.unlockedAtDateKey,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final bool isUnlocked;
  final String? unlockedAtDateKey;
  final String iconKey;

  Medal copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? isUnlocked,
    String? unlockedAtDateKey,
    bool clearUnlockedAtDateKey = false,
    String? iconKey,
  }) {
    return Medal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAtDateKey: clearUnlockedAtDateKey
          ? null
          : (unlockedAtDateKey ?? this.unlockedAtDateKey),
      iconKey: iconKey ?? this.iconKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'isUnlocked': isUnlocked,
      'unlockedAtDateKey': unlockedAtDateKey,
      'iconKey': iconKey,
    };
  }

  factory Medal.fromMap(Map<String, dynamic> map) {
    return Medal(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      unlockedAtDateKey: map['unlockedAtDateKey'] as String?,
      iconKey: map['iconKey'] as String? ?? 'medal',
    );
  }
}
