import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../main.dart'
    show
        themeNotifier,
        textScaleNotifier,
        colorThemeNotifier,
        authNotifier,
        homeCountyNotifier;
import '../services/auth.dart';
import '../services/theme_prefs.dart';
import '../services/user_profile.dart';
import '../utils/snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  final UserProfileService _profileService = UserProfileService();

  ThemeMode get _themeMode => themeNotifier.value;
  TextScaleOption get _textScale => textScaleNotifier.value;
  ColorThemeOption get _colorTheme => colorThemeNotifier.value;
  String? get _homeCounty => homeCountyNotifier.value;

  Future<void> _setHomeCounty(String county) async {
    homeCountyNotifier.value = county;
    if (mounted) setState(() {});
    await _profileService.setHomeCounty(county);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    themeNotifier.value = mode;
    if (mounted) setState(() {});
    await _themeService.setTheme(mode);
  }

  Future<void> _setTextScale(TextScaleOption option) async {
    textScaleNotifier.value = option;
    if (mounted) setState(() {});
    await _themeService.setTextScale(option);
  }

  Future<void> _setColorTheme(ColorThemeOption option) async {
    colorThemeNotifier.value = option;
    if (mounted) setState(() {});
    await _themeService.setColorTheme(option);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        showAppSnackBar(context, 'Could not open link', type: SnackType.error);
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in with Google any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().signOut();
      if (mounted) showAppSnackBar(context, 'Signed out', type: SnackType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
        children: [
          const _SectionHeader(title: 'Appearance'),

          _SettingsCard(
            icon: switch (_themeMode) {
              ThemeMode.dark => Icons.dark_mode_rounded,
              ThemeMode.light => Icons.light_mode_rounded,
              ThemeMode.system => Icons.brightness_auto_rounded,
            },
            title: 'Theme',
            subtitle: switch (_themeMode) {
              ThemeMode.dark => 'Dark theme active',
              ThemeMode.light => 'Light theme active',
              ThemeMode.system => 'Follows your device setting',
            },
            child: _OptionSelector<ThemeMode>(
              options: const [
                ThemeMode.light,
                ThemeMode.dark,
                ThemeMode.system,
              ],
              current: _themeMode,
              labelOf: (m) => switch (m) {
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
                ThemeMode.system => 'System',
              },
              onChanged: _setThemeMode,
            ),
          ),

          _SettingsCard(
            icon: Icons.palette_outlined,
            title: 'Accent Color',
            subtitle: _colorTheme.label,
            child: Wrap(
              spacing: AppTheme.spaceMedium,
              runSpacing: AppTheme.spaceMedium,
              children: ColorThemeOption.values
                  .map(
                    (option) => _ColorSwatch(
                      option: option,
                      selected: option == _colorTheme,
                      onTap: () => _setColorTheme(option),
                    ),
                  )
                  .toList(),
            ),
          ),

          _SettingsCard(
            icon: Icons.text_fields_rounded,
            title: 'Text Size',
            subtitle: _textScale.label,
            child: _OptionSelector<TextScaleOption>(
              options: TextScaleOption.values,
              current: _textScale,
              labelOf: (o) => o.label,
              onChanged: _setTextScale,
            ),
          ),

          const _SectionHeader(title: 'Personalization'),
          _SettingsCard(
            icon: Icons.location_city_outlined,
            title: 'Home County',
            subtitle:
                _homeCounty ??
                'Not set — Home shows records from all ${AppConstants.scopedCounties.length} counties',
            child: Wrap(
              spacing: AppTheme.spaceSmall,
              runSpacing: AppTheme.spaceSmall,
              children: [
                for (final county in AppConstants.scopedCounties)
                  ChoiceChip(
                    label: Text(county),
                    selected: _homeCounty == county,
                    onSelected: (_) => _setHomeCounty(county),
                  ),
              ],
            ),
          ),

          const _SectionHeader(title: 'Account'),
          ValueListenableBuilder<User?>(
            valueListenable: authNotifier,
            builder: (context, user, _) {
              final isGuest = AuthService.isGuest(user);
              return _SettingsCard(
                icon: isGuest
                    ? Icons.person_outline_rounded
                    : Icons.verified_user_rounded,
                title: isGuest
                    ? 'Browsing as a guest'
                    : (user?.displayName ?? 'Signed in'),
                subtitle: isGuest
                    ? 'Sign in from the Profile tab to save items'
                    : (user?.email ?? ''),
                child: isGuest
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _confirmSignOut,
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppTheme.error,
                          ),
                          label: const Text(
                            'Sign out',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ),
              );
            },
          ),

          const _SectionHeader(title: 'About'),
          _SettingsCard(
            icon: Icons.info_outline_rounded,
            title: AppConstants.appName,
            subtitle: 'Version ${AppConstants.appVersion}',
            child: const SizedBox.shrink(),
          ),
          ListTile(
            leading: const Icon(Icons.source_outlined),
            title: const Text('Official data source'),
            subtitle: Text(AppConstants.dataSourceName),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _openUrl(AppConstants.dataSourceUrl),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLarge,
        AppTheme.spaceLarge,
        AppTheme.spaceLarge,
        AppTheme.spaceSmall,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.caption.copyWith(
          color: AppTheme.textTertiaryOf(context),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLarge,
        vertical: AppTheme.spaceSmall,
      ),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryOf(context)),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyBold.copyWith(
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.subtitle.copyWith(
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (child is! SizedBox) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            child,
          ],
        ],
      ),
    );
  }
}

class _OptionSelector<T> extends StatelessWidget {
  final List<T> options;
  final T current;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _OptionSelector({
    required this.options,
    required this.current,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final selected = option == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spaceSmall,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryOf(context)
                      : AppTheme.surfaceLightOf(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  labelOf(option),
                  style: AppTheme.bodyBold.copyWith(
                    color: selected
                        ? Colors.white
                        : AppTheme.textSecondaryOf(context),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final ColorThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [option.primary, option.secondary]),
          border: selected
              ? Border.all(color: AppTheme.textPrimaryOf(context), width: 2.5)
              : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
