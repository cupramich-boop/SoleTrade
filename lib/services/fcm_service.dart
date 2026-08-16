import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/supabase/supabase_client.dart';

/// Rejestruje token FCM bieżącego urządzenia w tabeli `user_devices`.
class FcmService {
  static Future<void> registerDeviceToken() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token == null) return;

    final deviceType = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    await supabase.from('user_devices').upsert({
      'user_id': userId,
      'fcm_token': token,
      'device_type': deviceType,
    }, onConflict: 'user_id,fcm_token');

    messaging.onTokenRefresh.listen((newToken) async {
      await supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': newToken,
        'device_type': deviceType,
      }, onConflict: 'user_id,fcm_token');
    });
  }
}
