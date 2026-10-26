import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  User? get currentUser => _auth.currentUser;

  static bool isGuest(User? user) => user == null || user.isAnonymous;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    try {
      await _auth.signInAnonymously();
    } catch (_) {}
  }

  // popup flow on web, native google_sign_in on phones either way. Whatever the
  // guest had saved or asked EcoGuide gets carried over to the real account after.
  Future<({User? user, String? error})> signInWithGoogle() async {
    try {
      final previousUid = _auth.currentUser?.isAnonymous == true
          ? _auth.currentUser?.uid
          : null;
      final guestPrefs = previousUid == null
          ? null
          : await _readGuestPreferences(previousUid);
      final guestChatThreads = previousUid == null
          ? null
          : await _readGuestChatThreads(previousUid);

      final UserCredential result;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        result = await _auth.signInWithPopup(provider);
      } else {
        await _ensureGoogleSignInInitialized();
        try {
          await _googleSignIn.signOut();
        } catch (_) {}

        final GoogleSignInAccount googleUser;
        try {
          googleUser = await _googleSignIn.authenticate();
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) {
            return (user: null, error: null);
          }
          rethrow;
        }

        final credential = GoogleAuthProvider.credential(
          idToken: googleUser.authentication.idToken,
        );
        result = await _auth.signInWithCredential(credential);

        final fbUser = result.user;
        if (fbUser != null) {
          final needsName =
              fbUser.displayName == null || fbUser.displayName!.isEmpty;
          final needsPhoto =
              fbUser.photoURL == null || fbUser.photoURL!.isEmpty;
          if (needsName && googleUser.displayName != null) {
            await fbUser.updateDisplayName(googleUser.displayName);
          }
          if (needsPhoto && googleUser.photoUrl != null) {
            await fbUser.updatePhotoURL(googleUser.photoUrl);
          }
          if (needsName || needsPhoto) await fbUser.reload();
        }
      }

      final user = result.user;
      if (user == null) return (user: null, error: 'Sign-in failed');

      await Future.wait([
        _saveUserProfile(user),
        _mergeGuestPreferences(user.uid, guestPrefs),
        _mergeGuestChatThreads(user.uid, guestChatThreads),
      ]);
      return (user: user, error: null);
    } catch (e) {
      return (user: null, error: e.toString());
    }
  }

  Future<void> _saveUserProfile(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'display_name': user.displayName,
        'photo_url': user.photoURL,
        'email': user.email,
        'joined_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _readGuestPreferences(String guestUid) async {
    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(guestUid)
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  // carries over guest saves. won't overwrite a home county that's already set on the real account
  Future<void> _mergeGuestPreferences(
    String realUid,
    Map<String, dynamic>? guestPrefs,
  ) async {
    if (guestPrefs == null) return;
    final savedRecordIds = List<String>.from(
      guestPrefs['saved_record_ids'] ?? const [],
    );
    final savedReportIds = List<String>.from(
      guestPrefs['saved_report_ids'] ?? const [],
    );
    final homeCounty = guestPrefs['home_county'] as String?;
    if (savedRecordIds.isEmpty &&
        savedReportIds.isEmpty &&
        homeCounty == null) {
      return;
    }

    try {
      final ref = _firestore.collection('user_preferences').doc(realUid);
      final existing = await ref.get();
      final alreadyHasHomeCounty =
          (existing.data()?['home_county'] as String?) != null;

      await ref.set({
        if (savedRecordIds.isNotEmpty)
          'saved_record_ids': FieldValue.arrayUnion(savedRecordIds),
        if (savedReportIds.isNotEmpty)
          'saved_report_ids': FieldValue.arrayUnion(savedReportIds),
        if (homeCounty != null && !alreadyHasHomeCounty)
          'home_county': homeCounty,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>
  _readGuestChatThreads(String guestUid) async {
    try {
      final snap = await _firestore
          .collection('user_preferences')
          .doc(guestUid)
          .collection('ecoguide_chats')
          .get();
      return snap.docs;
    } catch (_) {
      return null;
    }
  }

  Future<void> _mergeGuestChatThreads(
    String realUid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? guestThreads,
  ) async {
    if (guestThreads == null || guestThreads.isEmpty) return;
    try {
      final realThreads = _firestore
          .collection('user_preferences')
          .doc(realUid)
          .collection('ecoguide_chats');
      final batch = _firestore.batch();
      var wrote = false;
      for (final doc in guestThreads) {
        final ref = realThreads.doc(doc.id);
        if ((await ref.get()).exists) continue;
        batch.set(ref, doc.data());
        wrote = true;
      }
      if (wrote) await batch.commit();
    } catch (_) {}
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    await ensureSignedIn();
  }
}
