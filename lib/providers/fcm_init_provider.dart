import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/fcm_service.dart';

/// Rejestruje token FCM po zalogowaniu; nie przerywa działania aplikacji,
/// jeśli Firebase nie jest jeszcze skonfigurowany w projekcie.
final fcmInitProvider = FutureProvider<void>((ref) async {
  try {
    await FcmService.registerDeviceToken();
  } catch (_) {
    // Firebase niedostępny — pomiń rejestrację push.
  }
});
