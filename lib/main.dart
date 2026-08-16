import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSupabase();

  // Firebase jest opcjonalny na etapie developmentu — wymaga `flutterfire configure`.
  // Powiadomienia push (FcmService) nie zadziałają, dopóki projekt nie zostanie skonfigurowany.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    debugPrint('Firebase nie jest skonfigurowany — pomijam inicjalizację FCM.');
  }

  runApp(const ProviderScope(child: SoleTradeApp()));
}
