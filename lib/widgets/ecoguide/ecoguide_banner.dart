import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import 'open_ecoguide.dart';

class EcoGuideBanner extends StatefulWidget {
  const EcoGuideBanner({super.key});

  @override
  State<EcoGuideBanner> createState() => _EcoGuideBannerState();
}

class _EcoGuideBannerState extends State<EcoGuideBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  static const _prompts = [
    'What is a stormwater permit?',
    'How do I report illegal dumping?',
    'Is it safe to swim here?',
  ];

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openEcoGuide(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.aiGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ai.withValues(alpha: 0.38),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(right: -40, top: -50, child: _orb(170, 0.10)),
            Positioned(right: 40, bottom: -70, child: _orb(140, 0.08)),
            Positioned(left: -30, bottom: -40, child: _orb(100, 0.06)),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) => Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(
                                  alpha: 0.25 + 0.25 * _pulse.value,
                                ),
                                blurRadius: 10 + 14 * _pulse.value,
                                spreadRadius: 1 + 4 * _pulse.value,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.ai,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EcoGuide AI',
                              style: AppTheme.h1.copyWith(
                                color: Colors.white,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    "Ask about a specific report — or anything about Maryland's land, water and air.",
                    style: AppTheme.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _prompts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppTheme.spaceSmall),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () =>
                            openEcoGuide(context, question: _prompts[i]),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusPill,
                            ),
                          ),
                          child: Text(
                            _prompts[i],
                            style: AppTheme.caption.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMedium,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_rounded,
                          color: AppTheme.ai,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ask EcoGuide anything…',
                            style: AppTheme.bodyBold.copyWith(
                              color: AppTheme.aiDeep,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            gradient: AppTheme.aiGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      shape: BoxShape.circle,
    ),
  );
}
