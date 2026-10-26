import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../main.dart' show mainScreenTabRequestNotifier;
import '../widgets/brand/brand_header.dart';
import '../widgets/brand/header_button.dart';
import '../widgets/nav/bottom_nav.dart';
import 'bulletin_board.dart';
import 'ecoguide_chat.dart';
import 'explore.dart';
import 'home.dart';
import 'new_report.dart';
import 'profile.dart';
import 'saved.dart';
import 'settings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 0-4 share the brand header/rounded-content chrome below; 5-7 are full
  // screens with their own app bar, just kept alive behind the same bottom nav
  static const _primaryScreens = [
    HomeScreen(),
    ExploreScreen(),
    BulletinBoardScreen(),
    ReportIssueScreen(),
    ProfileScreen(),
  ];

  static const _secondaryScreens = [
    EcoGuideScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  static const _headings = <int, (String, String)>{
    1: (
      'Explore Records',
      'Discover environmental records and community reports from across Maryland.',
    ),
    2: ('Community Bulletin', "See what cleanups and help events people nearby are organizing."),
    3: ('Report Issue', 'Help document an environmental concern.'),
    4: ('Profile', 'Your account, saved items, reports and EcoGuide chats.'),
  };

  @override
  void initState() {
    super.initState();
    mainScreenTabRequestNotifier.addListener(_onTabRequested);
  }

  @override
  void dispose() {
    mainScreenTabRequestNotifier.removeListener(_onTabRequested);
    super.dispose();
  }

  void _onTabRequested() {
    final requested = mainScreenTabRequestNotifier.value;
    if (requested == null) return;
    mainScreenTabRequestNotifier.value = null;
    if (requested != _currentIndex) setState(() => _currentIndex = requested);
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = _currentIndex <= 4;
    final heading = _headings[_currentIndex];
    final headerHeight = 96.0 + MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: isPrimary
          ? Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: BrandHeader(
                    height: headerHeight + 26,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeaderButton(
                          icon: _currentIndex == 4
                              ? Icons.person_rounded
                              : Icons.person_outline_rounded,
                          tooltip: 'Profile',
                          active: _currentIndex == 4,
                          onTap: () => setState(() => _currentIndex = 4),
                        ),
                        HeaderButton(
                          icon: Icons.settings_outlined,
                          tooltip: 'Settings',
                          onTap: () => setState(() => _currentIndex = 7),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  top: headerHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        if (heading != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppTheme.spaceMedium + 4,
                                AppTheme.spaceMedium + 2,
                                AppTheme.spaceMedium,
                                0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    heading.$1,
                                    style: AppTheme.h1.copyWith(
                                      color: AppTheme.textPrimaryOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    heading.$2,
                                    style: AppTheme.subtitle.copyWith(
                                      color: AppTheme.textSecondaryOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: _primaryScreens,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: _currentIndex - 5,
              children: _secondaryScreens,
            ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onSelect: (index) => setState(() => _currentIndex = index),
        onEcoGuide: () => setState(() => _currentIndex = 5),
      ),
    );
  }
}
