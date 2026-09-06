import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class VotDebugLogger {
  static VotDebugLogger? _instance;
  File? _logFile;
  bool _initialized = false;

  VotDebugLogger._();

  static VotDebugLogger get instance {
    _instance ??= VotDebugLogger._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/vot_debug.log');
      _initialized = true;
    } catch (e) {
      // ignore
    }
  }

  Future<void> clear() async {
    if (!_initialized || _logFile == null) return;
    try {
      if (await _logFile!.exists()) {
        await _logFile!.writeAsString('', mode: FileMode.write);
      }
      final String now = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final String header = '''
========================================
SITARA AI VOT DEBUG SESSION
START TIME: $now
========================================
''';
      await _logFile!.writeAsString(header, mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  Future<void> log(String message) async {
    if (!_initialized || _logFile == null) return;
    try {
      final String now = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final String formattedMessage = '[$now]\n$message\n\n';
      await _logFile!.writeAsString(formattedMessage, mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  Future<String?> getLogPath() async {
    if (!_initialized || _logFile == null) return null;
    return _logFile!.path;
  }
}
