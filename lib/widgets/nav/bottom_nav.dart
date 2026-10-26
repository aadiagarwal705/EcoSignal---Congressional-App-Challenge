import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onEcoGuide;

  const BottomNav({super.key, required this.currentIndex, required this.onSelect, required this.onEcoGuide});

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(bottom: inset),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        height: 66,
        child: Row(
          children: [
            Expanded(
              child: NavItem(
                icon: Icons.home_rounded,
                outlined: Icons.home_outlined,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
            ),
            Expanded(
              child: NavItem(
                icon: Icons.explore_rounded,
                outlined: Icons.explore_outlined,
                label: 'Explore',
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
            ),
            Expanded(child: EcoGuideNavButton(onTap: onEcoGuide)),
            Expanded(
              child: NavItem(
                icon: Icons.volunteer_activism_rounded,
                outlined: Icons.volunteer_activism_outlined,
                label: 'Events',
                selected: currentIndex == 2,
                onTap: () => onSelect(2),
              ),
            ),
            Expanded(
              child: NavItem(
                icon: Icons.add_circle_rounded,
                outlined: Icons.add_circle_outline_rounded,
                label: 'Report',
                selected: currentIndex == 3,
                onTap: () => onSelect(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlined;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.outlined,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryOf(context) : AppTheme.textTertiaryOf(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? icon : outlined, color: color, size: 26),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTheme.caption.copyWith(color: color, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class EcoGuideNavButton extends StatefulWidget {
  final VoidCallback onTap;

  const EcoGuideNavButton({super.key, required this.onTap});

  @override
  State<EcoGuideNavButton> createState() => _EcoGuideNavButtonState();
}

class _EcoGuideNavButtonState extends State<EcoGuideNavButton> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) => Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.ai.withValues(alpha: 0.35 + 0.25 * _glow.value), blurRadius: 8 + 8 * _glow.value, spreadRadius: 1),
                ],
              ),
              child: child,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 3),
          Text('EcoGuide', style: AppTheme.caption.copyWith(color: AppTheme.ai, fontWeight: FontWeight.w800, letterSpacing: 0)),
        ],
      ),
    );
  }
}
