import '../models/aac_card_model.dart';
import '../models/category_metadata.dart';

/// Captures an immutable snapshot of all board data and relevant state
/// when entering Edit Mode, ensuring atomic rollback on Cancel.
class EditSessionSnapshot {
  final List<AACCard> cards;
  final Map<String, Set<String>> visibleCardIdsByParent;
  final Set<String> allCategories;
  final Set<String> customCategories;
  final Set<String> selectedCategories;
  final String selectedCategory;
  final Map<String, CategoryMetadata> customCategoryMetadata;
  final String? activeParentId;
  final List<String> parentStackIds;
  final Set<String> initialMediaPaths;

  EditSessionSnapshot({
    required this.cards,
    required this.visibleCardIdsByParent,
    required this.allCategories,
    required this.customCategories,
    required this.selectedCategories,
    required this.selectedCategory,
    required this.customCategoryMetadata,
    required this.activeParentId,
    required this.parentStackIds,
    required this.initialMediaPaths,
  });
}
