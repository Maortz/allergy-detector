/// Minimum data contract for the next product awaiting community review.
///
/// See `review-next-item.md §6.2`. There is no Supabase table backing this yet
/// (#56 deferred), so the screen accepts an instance directly from its caller.
///
/// Immutable by design: the favourite-toggle state on [ReviewNextScreen] is
/// purely local UI state held in the widget's [State]; this model is owned by
/// the parent and is never mutated from within the screen.
class ReviewQueueItem {
  final String id;
  final String name;
  final String categoryLabel;
  final String description;
  final String imageUrl;
  final String alertLabel;

  const ReviewQueueItem({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.description,
    required this.imageUrl,
    required this.alertLabel,
  });
}
