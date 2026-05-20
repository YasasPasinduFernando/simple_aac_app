class AACCard {
  String id;
  String label;
  String? labelSinhala;
  String? labelTamil;
  String? imagePath;
  String? voicePath;
  String category;
  int colorValue;
  List<AACCard> subCards;
  String type; // 'word' or 'folder'

  AACCard({
    required this.id,
    required this.label,
    this.labelSinhala,
    this.labelTamil,
    this.imagePath,
    this.voicePath,
    this.category = 'General',
    required this.colorValue,
    List<AACCard>? subCards,
    this.type = 'word',
  }) : subCards = subCards ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'labelSinhala': labelSinhala,
        'labelTamil': labelTamil,
        'imagePath': imagePath,
        'voicePath': voicePath,
        'category': category,
        'colorValue': colorValue,
        'subCards': subCards.map((c) => c.toJson()).toList(),
        'type': type,
      };

  factory AACCard.fromJson(Map<String, dynamic> json) {
    final subCardsJson = json['subCards'] as List?;
    final subCards = subCardsJson
        ?.whereType<Map>()
        .map((c) => AACCard.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    final hasSubCards = subCards?.isNotEmpty ?? false;

    return AACCard(
      id: json['id']?.toString() ??
          'card_${DateTime.now().microsecondsSinceEpoch}',
      label: json['label']?.toString() ?? 'Untitled',
      labelSinhala: json['labelSinhala']?.toString(),
      labelTamil: json['labelTamil']?.toString(),
      imagePath: json['imagePath']?.toString(),
      voicePath: json['voicePath']?.toString(),
      category: json['category']?.toString() ?? 'General',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF90CAF9,
      subCards: subCards,
      type: json['type']?.toString() ?? (hasSubCards ? 'folder' : 'word'),
    );
  }

  String getLabel(String language) {
    String localizedOrDefault(String? localized) {
      final value = localized?.trim();
      if (value == null || value.isEmpty) return label;
      return value;
    }

    switch (language) {
      case 'si':
        return localizedOrDefault(labelSinhala);
      case 'ta':
        return localizedOrDefault(labelTamil);
      default:
        return label;
    }
  }
}
