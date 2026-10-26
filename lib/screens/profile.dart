import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../main.dart' show authNotifier, mainScreenTabRequestNotifier;
import '../models/community_report.dart';
import '../services/admin_tools.dart';
import '../services/auth.dart';
import '../services/reports.dart';
import '../utils/snackbar.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/google_sign_in_button.dart';
import '../widgets/record/record_card.dart';
import 'admin.dart';
import 'chat_history.dart';
import 'report_detail.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingIn = false;

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    final result = await AuthService().signInWithGoogle();
    if (!mounted) return;
    setState(() => _signingIn = false);
    if (result.user != null) {
      showAppSnackBar(
        context,
        'Signed in as ${result.user!.displayName ?? 'yourself'}',
        type: SnackType.success,
      );
    } else if (result.error != null) {
      showAppSnackBar(context, result.error!, type: SnackType.error);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    showAppSnackBar(context, 'Signed out', type: SnackType.info);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: authNotifier,
      builder: (context, user, _) {
        final isGuest = AuthService.isGuest(user);
        return ListView(
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          children: [
            _ProfileHeader(user: user, isGuest: isGuest),
            const SizedBox(height: AppTheme.spaceLarge),
            if (isGuest)
              GoogleSignInButton(loading: _signingIn, onPressed: _signIn)
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spaceMedium,
                    ),
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                ),
              ),
            if (!isGuest)
              StreamBuilder<bool>(
                stream: AdminService().isAdminStream,
                builder: (context, snapshot) {
                  if (snapshot.data != true) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spaceMedium),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.shield_outlined),
                        label: const Text('Admin — Review Reports'),
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spaceMedium),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => mainScreenTabRequestNotifier.value = 6,
                  icon: const Icon(Icons.bookmark_border_rounded),
                  label: const Text('Saved Items'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spaceMedium),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EcoGuideHistoryScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('My EcoGuide Chats'),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXLarge),
            Text(
              'My Reports',
              style: AppTheme.h3.copyWith(
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            if (isGuest)
              const EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No reports yet',
                message: 'Sign in and submit a report to see it here.',
              )
            else
              _MyReportsSection(key: ValueKey(user!.uid), uid: user.uid),
          ],
        );
      },
    );
  }
}

class _MyReportsSection extends StatefulWidget {
  final String uid;
  const _MyReportsSection({super.key, required this.uid});

  @override
  State<_MyReportsSection> createState() => _MyReportsSectionState();
}

class _MyReportsSectionState extends State<_MyReportsSection> {
  late Future<List<CommunityReport>> _future;

  @override
  void initState() {
    super.initState();
    _future = ReportService().getMyReports(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CommunityReport>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No reports yet',
            message: 'Tap the Report tab to submit your first one.',
          );
        }
        return Column(
          children: [
            for (final report in reports) ...[
              RecordCard(
                item: report,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(report: report),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
            ],
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User? user;
  final bool isGuest;

  const _ProfileHeader({required this.user, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL;
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppTheme.primaryOf(context).withValues(alpha: 0.12),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: AppTheme.primaryOf(context),
                )
              : null,
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isGuest
                    ? 'Browsing as a guest'
                    : (user?.displayName ?? 'EcoSignal user'),
                style: AppTheme.h3.copyWith(
                  color: AppTheme.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isGuest
                    ? 'Sign in to save items and report issues'
                    : (user?.email ?? ''),
                style: AppTheme.subtitle.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
