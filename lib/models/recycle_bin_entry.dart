import '../models/aac_card_model.dart';

/// Represents a deleted card or folder stored in the 30-day Recycle Bin.
class RecycleBinEntry {
  final String entryId;
  final AACCard card;
  final String? parentId;
  final int originalIndex;
  final DateTime deletedAtUtc;
  final List<String> referencedMediaPaths;

  RecycleBinEntry({
    required this.entryId,
    required this.card,
    this.parentId,
    required this.originalIndex,
    required this.deletedAtUtc,
    List<String>? referencedMediaPaths,
  }) : referencedMediaPaths = referencedMediaPaths ?? collectMediaPaths(card);

  /// Recursively collect all media paths referenced by this card and all descendants.
  static List<String> collectMediaPaths(AACCard root) {
    final paths = <String>{};
    void walk(AACCard c) {
      final img = c.imagePath?.trim();
      if (img != null && img.isNotEmpty) {
        paths.add(img);
      }
      final voice = c.voicePath?.trim();
      if (voice != null && voice.isNotEmpty) {
        paths.add(voice);
      }
      for (final sub in c.subCards) {
        walk(sub);
      }
    }

    walk(root);
    return paths.toList();
  }

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'card': card.toJson(),
        'parentId': parentId,
        'originalIndex': originalIndex,
        'deletedAtUtc': deletedAtUtc.toIso8601String(),
        'referencedMediaPaths': referencedMediaPaths,
      };

  factory RecycleBinEntry.fromJson(Map<String, dynamic> json) {
    return RecycleBinEntry(
      entryId: json['entryId']?.toString() ?? '',
      card: AACCard.fromJson(Map<String, dynamic>.from(json['card'] as Map)),
      parentId: json['parentId']?.toString(),
      originalIndex: (json['originalIndex'] as num?)?.toInt() ?? 0,
      deletedAtUtc: DateTime.tryParse(json['deletedAtUtc']?.toString() ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc(),
      referencedMediaPaths: (json['referencedMediaPaths'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Calculates days remaining before this entry expires (0 to 30).
  int getDaysRemaining([DateTime? now]) {
    final current = (now ?? DateTime.now()).toUtc();
    final elapsedDays = current.difference(deletedAtUtc).inDays;
    final remaining = 30 - elapsedDays;
    return remaining < 0 ? 0 : (remaining > 30 ? 30 : remaining);
  }

  /// Whether this entry is 30 or more days old and eligible for automatic purge.
  bool isExpired([DateTime? now]) {
    final current = (now ?? DateTime.now()).toUtc();
    return current.difference(deletedAtUtc).inDays >= 30;
  }

  /// Formatted metadata string matching the UI mockup:
  /// "Deleted today · 30 days left" / "Deleted 3 days ago · 27 days left"
  String getDeletionStatusText([DateTime? now]) {
    final current = (now ?? DateTime.now()).toUtc();
    final elapsedDays = current.difference(deletedAtUtc).inDays;
    final remainingDays = getDaysRemaining(current);

    final String elapsedStr;
    if (elapsedDays <= 0) {
      elapsedStr = 'Deleted today';
    } else if (elapsedDays == 1) {
      elapsedStr = 'Deleted 1 day ago';
    } else {
      elapsedStr = 'Deleted $elapsedDays days ago';
    }

    final String remainingStr;
    if (remainingDays == 1) {
      remainingStr = '1 day left';
    } else {
      remainingStr = '$remainingDays days left';
    }

    return '$elapsedStr · $remainingStr';
  }
}
