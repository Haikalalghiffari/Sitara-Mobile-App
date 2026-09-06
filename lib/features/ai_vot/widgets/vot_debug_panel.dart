import 'package:flutter/material.dart';
import '../models/vot_debug_state.dart';

/// Panel debug overlay yang menampilkan data realtime VOT.
///
/// Menggunakan [ValueListenableBuilder] sehingga hanya panel ini
/// yang rebuild setiap frame, bukan seluruh halaman.
class VotDebugPanel extends StatelessWidget {
  const VotDebugPanel({
    super.key,
    required this.notifier,
  });

  final VotDebugNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VotDebugState>(
      valueListenable: notifier,
      builder: (BuildContext context, VotDebugState s, _) {
        return IgnorePointer(
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: s.sequenceCompleted
                    ? Colors.green
                    : s.timedOut
                        ? Colors.red
                        : Colors.cyan.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Colors.white,
                height: 1.3,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header('🐞 AI VOT DEBUG'),
                    const SizedBox(height: 2),

                    // ── 1. CAMERA ──
                    _section('1. CAMERA'),
                    _row('Stream', s.streamActive ? 'ACTIVE' : 'INACTIVE',
                        s.streamActive ? Colors.green : Colors.red),
                    _row('Resolution', s.cameraResolution, Colors.white70),
                    _row('Lens', s.cameraLens, Colors.white70),
                    _row('Orientation', '${s.sensorOrientation}', Colors.white70),
                    _row('Recording', s.recording ? 'YES' : 'NO',
                        s.recording ? Colors.green : Colors.orange),
                    _row('Last Frame',
                        s.lastFrameTime != null
                            ? '${DateTime.now().difference(s.lastFrameTime!).inMilliseconds}ms ago'
                            : '-',
                        s.cameraStreamStalled ? Colors.red : Colors.white70),
                    if (s.cameraStreamStalled)
                      _alert('CAMERA STREAM STALLED', Colors.red),

                    // ── 2. FACE ──
                    _section('2. FACE'),
                    _row('Face Mesh', s.faceDetected ? 'DETECTED' : 'NOT DETECTED',
                        s.faceDetected ? Colors.green : Colors.red),
                    _row('Face Frames', '${s.faceFrameCount}', Colors.white70),
                    _row('Mouth X', _f(s.mouthX), Colors.white70),
                    _row('Mouth Y', _f(s.mouthY), Colors.white70),

                    // ── 3. HAND ──
                    _section('3. HAND'),
                    _row('Hand', s.handDetected ? 'DETECTED' : 'NOT DETECTED',
                        s.handDetected ? Colors.green : Colors.red),
                    _row('Hand Frames', '${s.handFrameCount}', Colors.white70),
                    _row('Hand Age', '${s.handDataAge.inMilliseconds}ms',
                        s.handDataStale ? Colors.orange : Colors.white70),
                    if (s.handDataStale)
                      _alert('STALE HAND DATA', Colors.orange),

                    // ── 4. DISTANCE ──
                    _section('4. DISTANCE'),
                    _row('Distance', _f(s.distance),
                        _distanceColor(s.distance, s.nearThreshold, s.farThreshold)),
                    _row('Min', _f(s.minDistance), Colors.white70),
                    _row('Max', _f(s.maxDistance), Colors.white70),
                    _row('Near Thr', s.nearThreshold.toStringAsFixed(3), Colors.cyan),
                    _row('Far Thr', s.farThreshold.toStringAsFixed(3), Colors.cyan),
                    _row('NEAR', s.nearReached ? 'YES ✓' : 'NO',
                        s.nearReached ? Colors.green : Colors.yellow),
                    _row('FAR', s.farReached ? 'YES ✓' : 'NO',
                        s.farReached ? Colors.green : Colors.yellow),
                    _row('WITHDRAW', s.withdrawingDetected ? 'YES ✓' : 'NO',
                        s.withdrawingDetected ? Colors.green : Colors.yellow),

                    // ── 5. DRINKING STATE ──
                    _section('5. STATE'),
                    _row('Current', s.currentStage, _stageColor(s.currentStage)),
                    _row('Max', s.maxStage, _stageColor(s.maxStage)),

                    // ── 6. SEQUENCE STATUS ──
                    _section('6. STATUS'),
                    _row('FACE LOST', s.faceLost ? 'YES' : 'NO',
                        s.faceLost ? Colors.red : Colors.green),
                    _row('HAND LOST', s.handLost ? 'YES' : 'NO',
                        s.handLost ? Colors.red : Colors.green),
                    _row('DIST NULL', s.distanceNull ? 'YES' : 'NO',
                        s.distanceNull ? Colors.red : Colors.green),
                    _row('TIMEOUT', s.timedOut ? 'YES' : 'NO',
                        s.timedOut ? Colors.red : Colors.green),
                    _row('Frames', '${s.totalFrames}', Colors.white70),

                    // ── 7. DIAGNOSTIC REASON ──
                    _section('7. DIAGNOSTIC'),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        s.diagnosticReason.isNotEmpty
                            ? s.diagnosticReason
                            : '-',
                        style: TextStyle(
                          fontSize: 9,
                          color: s.sequenceCompleted
                              ? Colors.green
                              : Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ── 8. MIRRORING / COORDINATES ──
                    _section('8. COORDINATES'),
                    _row('Front Cam', s.frontCamera ? 'YES' : 'NO', Colors.cyan),
                    _row('Mirror', s.handMirrorApplied ? 'YES' : 'NO', Colors.cyan),
                    const SizedBox(height: 2),
                    _coordRow('Mouth', s.mouthX, s.mouthY),
                    _coordRow('Thumb4', s.thumbTipX, s.thumbTipY,
                        rawX: s.thumbTipRawX),
                    _coordRow('Index8', s.indexTipX, s.indexTipY,
                        rawX: s.indexTipRawX),
                    _coordRow('Mid12', s.middleTipX, s.middleTipY,
                        rawX: s.middleTipRawX),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ──

  static String _f(double? v) => v?.toStringAsFixed(3) ?? 'null';

  static Widget _header(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.cyan,
      ),
    );
  }

  static Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 1),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.cyanAccent,
        ),
      ),
    );
  }

  static Widget _row(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 8, color: Colors.white54),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 9, color: valueColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _coordRow(String label, double? x, double? y, {double? rawX}) {
    final String rawInfo = rawX != null ? ' (raw:${rawX.toStringAsFixed(3)})' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Text(
        '$label X:${_f(x)} Y:${_f(y)}$rawInfo',
        style: const TextStyle(fontSize: 8, color: Colors.white70),
      ),
    );
  }

  static Widget _alert(String msg, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '⚠ $msg',
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  static Color _distanceColor(double? distance, double near, double far) {
    if (distance == null) return Colors.grey;
    if (distance <= near) return Colors.green;
    if (distance <= far) return Colors.yellow;
    return Colors.red;
  }

  static Color _stageColor(String stage) {
    return switch (stage) {
      'completed' => Colors.green,
      'nearMouth' => Colors.greenAccent,
      'withdrawing' => Colors.lightGreenAccent,
      'approachingMouth' => Colors.yellow,
      'handWithMedicine' => Colors.orange,
      'waiting' => Colors.white54,
      _ => Colors.white70,
    };
  }
}
