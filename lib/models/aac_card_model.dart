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

  factory AACCard.fromJson(Map<String, dynamic> json) => AACCard(
        id: json['id'],
        label: json['label'],
        labelSinhala: json['labelSinhala'],
        labelTamil: json['labelTamil'],
        imagePath: json['imagePath'],
        voicePath: json['voicePath'],
        category: json['category'] ?? 'General',
        colorValue: json['colorValue'],
        subCards: (json['subCards'] as List?)
            ?.map((c) => AACCard.fromJson(c))
            .toList(),
        type: json['type'] ??
            (((json['subCards'] as List?)?.isNotEmpty ?? false)
                ? 'folder'
                : 'word'),
      );

  String getLabel(String language) {
    switch (language) {
      case 'si':
        return labelSinhala ?? label;
      case 'ta':
        return labelTamil ?? label;
      default:
        return label;
    }
  }
}
