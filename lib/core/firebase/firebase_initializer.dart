import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

class FirebaseInitializer {
  static Future<void> initialize({
    bool useEmulator = false,
    String emulatorHost = 'localhost',
    int emulatorPort = 8080,
  }) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final endpoint = _resolveEmulatorEndpoint(
      useEmulator: useEmulator,
      emulatorHost: emulatorHost,
      emulatorPort: emulatorPort,
    );

    if (endpoint != null) {
      FirebaseFirestore.instance.useFirestoreEmulator(endpoint.host, endpoint.port);
      debugPrint('Firestore emulator enabled at ${endpoint.host}:${endpoint.port}');
    }
  }
}

class _EmulatorEndpoint {
  final String host;
  final int port;

  const _EmulatorEndpoint(this.host, this.port);
}

_EmulatorEndpoint? _resolveEmulatorEndpoint({
  required bool useEmulator,
  required String emulatorHost,
  required int emulatorPort,
}) {
  const hostFromDefine = String.fromEnvironment('FIRESTORE_EMULATOR_HOST');
  if (hostFromDefine.isNotEmpty) {
    return _parseEndpoint(hostFromDefine);
  }

  if (!kIsWeb) {
    final hostFromEnv = Platform.environment['FIRESTORE_EMULATOR_HOST'];
    if (hostFromEnv != null && hostFromEnv.isNotEmpty) {
      return _parseEndpoint(hostFromEnv);
    }
  }

  if (useEmulator) {
    return _EmulatorEndpoint(emulatorHost, emulatorPort);
  }

  return null;
}

_EmulatorEndpoint? _parseEndpoint(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    return null;
  }

  final port = int.tryParse(parts[1]);
  if (port == null) {
    return null;
  }

  return _EmulatorEndpoint(parts[0], port);
}
