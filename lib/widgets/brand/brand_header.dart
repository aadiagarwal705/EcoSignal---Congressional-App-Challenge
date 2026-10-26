import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class BrandHeader extends StatelessWidget {
  final double height;
  final bool showTagline;
  final Widget? trailing;
  final Widget? leading;

  const BrandHeader({
    super.key,
    this.height = 132,
    this.showTagline = true,
    this.trailing,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = dark ? const Color(0xFFEAF2ED) : AppTheme.textPrimary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? const [Color(0xFF16302A), Color(0xFF0E1512)]
                    : const [Color(0xFFCFE6F6), Color(0xFFEAF5EE)],
              ),
            ),
          ),
          Opacity(
            opacity: dark ? 0.35 : 1,
            child: Image.asset(
              'assets/images/header_banner.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (dark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                  (dark ? Colors.black : Colors.white).withValues(alpha: 0.0),
                ],
                stops: const [0.35, 0.85],
              ),
            ),
          ),
          if (showTagline)
            Positioned(
              left: AppTheme.spaceMedium + 4,
              right: AppTheme.spaceMedium,
              bottom: 32,
              child: Text(
                'Track and report environmental activity across Maryland',
                style: AppTheme.subtitle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dark ? const Color(0xFFB7C7BE) : AppTheme.brandDeep,
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMedium,
                6,
                AppTheme.spaceSmall,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ?leading,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3FAE73),
                                    AppTheme.brandDeep,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.brandGreen.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'EcoSignal ',
                                    style: TextStyle(color: titleColor),
                                  ),
                                  TextSpan(
                                    text: 'MD',
                                    style: TextStyle(
                                      color: dark
                                          ? const Color(0xFF6BD39A)
                                          : AppTheme.brandGreen,
                                    ),
                                  ),
                                ],
                              ),
                              style: AppTheme.h1.copyWith(
                                fontSize: 24,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
