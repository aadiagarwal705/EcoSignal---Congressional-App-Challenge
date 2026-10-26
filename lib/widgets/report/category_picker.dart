import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';

class CategoryPicker extends StatelessWidget {
  final ReportCategory? selected;
  final ValueChanged<ReportCategory> onSelected;

  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ReportCategory.values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppTheme.spaceSmall,
        crossAxisSpacing: AppTheme.spaceSmall,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final category = ReportCategory.values[index];
        final isSelected = category == selected;
        return _CategoryTile(
          category: category,
          selected: isSelected,
          onTap: () => onSelected(category),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ReportCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.primaryOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : AppTheme.surfaceLightOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: selected ? accent : AppTheme.textSecondaryOf(context),
              size: 26,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTheme.caption.copyWith(
                  color: selected ? accent : AppTheme.textSecondaryOf(context),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
