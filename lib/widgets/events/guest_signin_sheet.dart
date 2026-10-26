import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/auth.dart';
import '../../utils/snackbar.dart';
import '../common/google_sign_in_button.dart';

// same idea as SignInPrompt, just as a sheet for a button guests can see but not use yet
Future<bool> showGuestSignInSheet(BuildContext context, {required String message}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _GuestSignInSheet(message: message),
  ).then((v) => v ?? false);
}

class _GuestSignInSheet extends StatefulWidget {
  final String message;
  const _GuestSignInSheet({required this.message});

  @override
  State<_GuestSignInSheet> createState() => _GuestSignInSheetState();
}

class _GuestSignInSheetState extends State<_GuestSignInSheet> {
  bool _signingIn = false;

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    final result = await AuthService().signInWithGoogle();
    if (!mounted) return;
    if (result.user != null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _signingIn = false);
    if (result.error != null) {
      showAppSnackBar(context, result.error!, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spaceLarge,
        AppTheme.spaceLarge,
        AppTheme.spaceLarge,
        AppTheme.spaceLarge + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded, size: 48, color: AppTheme.primaryOf(context).withValues(alpha: 0.6)),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Sign in to continue',
              style: AppTheme.h3.copyWith(color: AppTheme.textPrimaryOf(context)),
            ),
            const SizedBox(height: 6),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(color: AppTheme.textSecondaryOf(context)),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            GoogleSignInButton(loading: _signingIn, onPressed: _signIn),
          ],
        ),
      ),
    );
  }
}
