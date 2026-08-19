import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';

/// Yükleme iskeletleri — spinner yerine içerik biçiminde parlayan
/// (shimmer) placeholder'lar. Premium yükleme deneyiminin temelidir.
///
/// Kullanım:
/// ```dart
/// Shimmer(
///   child: Column(children: [SkeletonBox(height: 14, width: 120), ...]),
/// )
/// ```
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.border,
                AppColors.surfaceTint,
                AppColors.border,
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: _SlidingGradient(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Gradyanı soldan sağa kaydırarak parlama efekti üretir.
class _SlidingGradient extends GradientTransform {
  const _SlidingGradient(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (progress * 3 - 1.5),
      0,
      0,
    );
  }
}

/// Tek bir iskelet kutusu (satır, daire, blok).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
    this.circle = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}
