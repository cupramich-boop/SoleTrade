import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';

/// Emituje bieżący stan sesji Supabase (zalogowany / niezalogowany).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.valueOrNull?.session?.user ?? supabase.auth.currentUser;
});

class AuthController {
  AuthController();

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

    if (kIsWeb) {
      await supabase.auth.signInWithOAuth(OAuthProvider.google);
      return;
    }

    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: ['email'],
    );

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;

    final idToken = googleAuth?.idToken;
    final accessToken = googleAuth?.accessToken;

    if (idToken == null) {
      throw AuthException('Logowanie Google nie powiodło się.');
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() => supabase.auth.signOut();
}

final authControllerProvider = Provider((ref) => AuthController());
