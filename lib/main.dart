import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'screens/shell.dart';
import 'services/auth.dart';
import 'services/theme_prefs.dart';
import 'services/user_profile.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<TextScaleOption> textScaleNotifier = ValueNotifier(
  TextScaleOption.medium,
);
final ValueNotifier<ColorThemeOption> colorThemeNotifier = ValueNotifier(
  ColorThemeOption.forest,
);
final ValueNotifier<User?> authNotifier = ValueNotifier(null);

final ValueNotifier<String?> homeCountyNotifier = ValueNotifier(null);

final ValueNotifier<int?> mainScreenTabRequestNotifier = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  authNotifier.value = FirebaseAuth.instance.currentUser;
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    authNotifier.value = user;
    try {
      final s = await ThemeService().loadAll();
      themeNotifier.value = s.theme;
      textScaleNotifier.value = s.textScale;
      colorThemeNotifier.value = s.colorTheme;
      homeCountyNotifier.value = await UserProfileService().getHomeCounty();
    } catch (_) {}
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        themeNotifier,
        textScaleNotifier,
        colorThemeNotifier,
      ]),
      builder: (_, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        themeMode: themeNotifier.value,
        theme: AppTheme.lightThemeFor(colorThemeNotifier.value),
        darkTheme: AppTheme.darkThemeFor(colorThemeNotifier.value),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleNotifier.value.scaleFactor),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child!,
          ),
        ),
        home: const SplashWrapper(),
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final start = DateTime.now();

    await AuthService().ensureSignedIn().timeout(
      const Duration(seconds: 6),
      onTimeout: () {},
    );

    final settings = await ThemeService().loadAll();
    themeNotifier.value = settings.theme;
    textScaleNotifier.value = settings.textScale;
    colorThemeNotifier.value = settings.colorTheme;
    homeCountyNotifier.value = await UserProfileService().getHomeCounty();

    final elapsed = DateTime.now().difference(start);
    final remaining = const Duration(milliseconds: 900) - elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return _splash();
    return const MainScreen();
  }

  Widget _splash() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/splash_screen.png',
          width: MediaQuery.sizeOf(context).width * 0.62,
        ),
      ),
    );
  }
}
