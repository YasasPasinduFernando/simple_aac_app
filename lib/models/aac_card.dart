class AACCard {
  String id;
  String label;
  String? imagePath;
  String? voicePath;
  int colorValue;
  List<AACCard> subCards;

  AACCard({
    required this.id,
    required this.label,
    this.imagePath,
    this.voicePath,
    required this.colorValue,
    List<AACCard>? subCards,
  }) : subCards = subCards ?? [];

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'imagePath': imagePath,
      'voicePath': voicePath,
      'colorValue': colorValue,
      'subCards': subCards.map((card) => card.toJson()).toList(),
    };
  }

  // Create from JSON
  factory AACCard.fromJson(Map<String, dynamic> json) {
    return AACCard(
      id: json['id'],
      label: json['label'],
      imagePath: json['imagePath'],
      voicePath: json['voicePath'],
      colorValue: json['colorValue'],
      subCards: (json['subCards'] as List?)
              ?.map((card) => AACCard.fromJson(card))
              .toList() ??
          [],
    );
  }
}
