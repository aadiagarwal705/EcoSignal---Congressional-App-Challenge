import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/auth.dart';
import '../../utils/snackbar.dart';
import '../../widgets/common/google_sign_in_button.dart';

class SignInPrompt extends StatefulWidget {
  const SignInPrompt({super.key});

  @override
  State<SignInPrompt> createState() => _SignInPromptState();
}

class _SignInPromptState extends State<SignInPrompt> {
  bool _signingIn = false;

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    final result = await AuthService().signInWithGoogle();
    if (!mounted) return;
    setState(() => _signingIn = false);
    if (result.error != null) {
      showAppSnackBar(context, result.error!, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 64,
              color: AppTheme.primaryOf(context).withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'Sign in to report an issue',
              style: AppTheme.h2.copyWith(
                color: AppTheme.textPrimaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              "Reports are tied to your account so we can keep the app free of spam and let you track what you've submitted.",
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXLarge),
            GoogleSignInButton(loading: _signingIn, onPressed: _signIn),
          ],
        ),
      ),
    );
  }
}
