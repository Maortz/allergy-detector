import 'package:flutter/material.dart';

/// A pulsing rectangular shimmer placeholder used by Tier 2 loading states.
///
/// Single shared widget so loading layouts across screens stay visually
/// consistent (`home-dashboard.md §5`, `community-hub.md §5.2`,
/// `review-next-item.md §5.2`, `settings-profile.md §5.7`,
/// `active-search-results.md §5.1`).
///
/// Lives off a single owning [AnimationController] disposed in [State.dispose].
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              colorScheme.surfaceContainerHigh,
              colorScheme.surfaceContainerHighest,
              t,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
