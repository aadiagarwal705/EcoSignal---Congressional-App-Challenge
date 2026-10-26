import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppTheme.radiusSmall,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
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
    final base = AppTheme.surfaceLightOf(context);
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.85);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 3, 0),
              end: Alignment(0 + _controller.value * 3, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const ShimmerList({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.all(AppTheme.spaceMedium),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceMedium),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            const ShimmerBox(
              width: 48,
              height: 48,
              borderRadius: AppTheme.radiusPill,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: double.infinity, height: 15),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: MediaQuery.sizeOf(context).width * 0.4,
                    height: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            const ShimmerBox(
              width: 64,
              height: 22,
              borderRadius: AppTheme.radiusPill,
            ),
          ],
        ),
      ),
    );
  }
}
