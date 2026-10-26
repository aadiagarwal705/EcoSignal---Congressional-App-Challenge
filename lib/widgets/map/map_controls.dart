import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../common/county_dropdown.dart';

enum MapFilter { all, official, community, events }

class LoadingChip extends StatelessWidget {
  const LoadingChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: AppTheme.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        boxShadow: AppTheme.shadowOf(context),
      ),
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class MapControls extends StatelessWidget {
  final MapFilter filter;
  final Set<String> selectedCounties;
  final ValueChanged<MapFilter> onFilterChanged;
  final ValueChanged<Set<String>> onCountiesChanged;

  const MapControls({
    super.key,
    required this.filter,
    required this.selectedCounties,
    required this.onFilterChanged,
    required this.onCountiesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            boxShadow: AppTheme.shadowOf(context),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in MapFilter.values)
                FilterPill(
                  label: switch (f) {
                    MapFilter.all => 'All',
                    MapFilter.official => 'Official',
                    MapFilter.community => 'Community',
                    MapFilter.events => 'Events',
                  },
                  selected: filter == f,
                  color: switch (f) {
                    MapFilter.all => AppTheme.brandGreen,
                    MapFilter.official => AppTheme.officialBadge,
                    MapFilter.community => AppTheme.actionBlue,
                    MapFilter.events => AppTheme.eventBadge,
                  },
                  onTap: () => onFilterChanged(f),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceOf(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.shadowOf(context),
          ),
          child: CountyDropdown(value: selectedCounties, onChanged: onCountiesChanged),
        ),
      ],
    );
  }
}

class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          label,
          style: AppTheme.bodyBold.copyWith(
            color: selected ? Colors.white : AppTheme.textSecondaryOf(context),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
