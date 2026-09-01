import 'package:flutter/services.dart';

import '../models/verification_state.dart';

/// FLAG_KEEP_SCREEN_ON hanya selama sesi VOT. Bukan always-on aplikasi.
bool shouldKeepVotScreenAwake({
  required VerificationState state,
  required bool phaseError,
}) {
  return state.keepScreenAwake && !phaseError;
}

class VotScreenAwake {
  VotScreenAwake({Future<void> Function(String method)? invoke})
    : _invoke = invoke ?? _invokePlatform;

  static const MethodChannel _channel = MethodChannel('sitara/screen_awake');

  final Future<void> Function(String method) _invoke;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> sync({required bool keepOn}) async {
    if (_enabled == keepOn) return;
    _enabled = keepOn;
    try {
      await _invoke(keepOn ? 'enable' : 'disable');
    } catch (_) {}
  }

  Future<void> disable() => sync(keepOn: false);

  static Future<void> _invokePlatform(String method) {
    return _channel.invokeMethod<void>(method);
  }
}
