import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/utils/drinking_sequence.dart';
import 'package:sitara/features/ai_vot/utils/vot_identity_lock.dart';

void main() {
  final DateTime t0 = DateTime(2026, 9, 6, 8);

  group('Identity lock sesi VOT', () {
    test('TEST 1: verifikasi awal berhasil mengunci identitas', () {
      final VotIdentityLock lock = VotIdentityLock();
      expect(lock.identityVerified, isFalse);
      expect(lock.shouldVerifyIdentity, isTrue);

      lock.lock(now: t0);

      expect(lock.identityVerified, isTrue);
      expect(lock.shouldVerifyIdentity, isFalse);
      expect(lock.lastFaceSeenAt, t0);
    });

    test('TEST 2: menoleh setelah terkunci tidak melepas identitas', () {
      final VotIdentityLock lock = VotIdentityLock();
      lock.lock(now: t0);

      // Frame wajah hilang-muncul karena menoleh kiri/kanan.
      for (int i = 1; i <= 20; i++) {
        lock.evaluate(
          facePresent: i.isEven,
          now: t0.add(Duration(milliseconds: 200 * i)),
        );
        expect(lock.identityVerified, isTrue);
      }
    });

    test('TEST 3 & 4: identitas terkunci tidak pernah minta verifikasi lagi',
        () {
      final VotIdentityLock lock = VotIdentityLock();
      lock.lock(now: t0);

      // Menunduk mengambil obat, lalu mengangkat obat ke mulut.
      for (int i = 1; i <= 50; i++) {
        lock.evaluate(facePresent: false, now: t0.add(Duration(seconds: i)));
        expect(lock.shouldVerifyIdentity, isFalse);
      }
    });

    test('TEST 7: wajah hilang di bawah masa tenggang hanya lostWithinGrace',
        () {
      final VotIdentityLock lock = VotIdentityLock();
      lock.lock(now: t0);

      expect(
        lock.evaluate(
          facePresent: false,
          now: t0.add(const Duration(seconds: 3)),
        ),
        FacePresenceStatus.lostWithinGrace,
      );
      expect(lock.identityVerified, isTrue);
    });

    test('TEST 8: wajah hilang melewati masa tenggang jadi peringatan saja',
        () {
      final VotIdentityLock lock = VotIdentityLock();
      lock.lock(now: t0);

      expect(
        lock.evaluate(
          facePresent: false,
          now: t0.add(VotIdentityLock.gracePeriod),
        ),
        FacePresenceStatus.lostTooLong,
      );
      // Peringatan, bukan reset identitas.
      expect(lock.identityVerified, isTrue);
      expect(lock.shouldVerifyIdentity, isFalse);
    });

    test('wajah kembali terlihat menyegarkan masa tenggang', () {
      final VotIdentityLock lock = VotIdentityLock();
      lock.lock(now: t0);

      expect(
        lock.evaluate(
          facePresent: false,
          now: t0.add(const Duration(seconds: 4)),
        ),
        FacePresenceStatus.lostWithinGrace,
      );
      expect(
        lock.evaluate(
          facePresent: true,
          now: t0.add(const Duration(seconds: 5)),
        ),
        FacePresenceStatus.present,
      );
      expect(
        lock.evaluate(
          facePresent: false,
          now: t0.add(const Duration(seconds: 9)),
        ),
        FacePresenceStatus.lostWithinGrace,
      );
    });

    test('reset melepas kunci untuk sesi yang dibatalkan', () {
      final VotIdentityLock lock = VotIdentityLock();
      lock.lock(now: t0);
      lock.reset();

      expect(lock.identityVerified, isFalse);
      expect(lock.shouldVerifyIdentity, isTrue);
      expect(lock.lastFaceSeenAt, isNull);
    });

    test('markFaceSeen tidak mengunci identitas yang belum diverifikasi', () {
      final VotIdentityLock lock = VotIdentityLock();
      lock.markFaceSeen(t0);

      expect(lock.identityVerified, isFalse);
      expect(lock.lastFaceSeenAt, isNull);
    });

    test('TEST 9: satu sesi hanya memanggil face verify sekali', () {
      final VotIdentityLock lock = VotIdentityLock();
      int faceVerifyRequests = 0;

      // 200 frame kamera; hanya frame sebelum terkunci boleh memanggil API.
      for (int frame = 0; frame < 200; frame++) {
        final DateTime now = t0.add(Duration(milliseconds: 33 * frame));
        if (lock.shouldVerifyIdentity) {
          faceVerifyRequests++;
          lock.lock(now: now);
          continue;
        }
        lock.evaluate(facePresent: frame.isEven, now: now);
      }

      expect(faceVerifyRequests, 1);
    });
  });

  group('Deteksi minum tahan terhadap wajah hilang sesaat', () {
    DrinkingSequenceMachine machine() =>
        DrinkingSequenceMachine(minDwell: Duration.zero);

    test('TEST 5 & 6: urutan minum selesai walau wajah tertutup tangan', () {
      final DrinkingSequenceMachine sequence = machine();
      final VotIdentityLock lock = VotIdentityLock();
      lock.lock(now: t0);

      DateTime now = t0;
      DrinkingStage tick(double? distance, {required bool facePresent}) {
        now = now.add(const Duration(milliseconds: 200));
        final FacePresenceStatus presence = lock.evaluate(
          facePresent: facePresent,
          now: now,
        );
        return sequence.update(
          handVisible: distance != null,
          faceVisible: facePresent,
          handMouthDistance: distance,
          now: now,
          faceLostWithinGrace:
              presence == FacePresenceStatus.lostWithinGrace,
        );
      }

      expect(tick(0.50, facePresent: true), DrinkingStage.handWithMedicine);
      expect(tick(0.40, facePresent: true), DrinkingStage.approachingMouth);
      // Tangan menutupi wajah saat obat menempel ke mulut; jarak masih
      // terbaca dari posisi mulut yang diingat.
      expect(tick(0.18, facePresent: false), DrinkingStage.nearMouth);
      expect(tick(0.28, facePresent: false), DrinkingStage.withdrawing);
      expect(tick(0.40, facePresent: true), DrinkingStage.completed);
      expect(sequence.maxStageReached, DrinkingStage.completed);
    });

    test('wajah hilang tanpa geometri menahan tahap, bukan mengulang', () {
      final DrinkingSequenceMachine sequence = machine();
      DateTime now = t0;

      sequence.update(
        handVisible: true,
        faceVisible: true,
        handMouthDistance: 0.50,
        now: now,
      );
      now = now.add(const Duration(milliseconds: 200));
      sequence.update(
        handVisible: true,
        faceVisible: true,
        handMouthDistance: 0.40,
        now: now,
      );
      expect(sequence.stage, DrinkingStage.approachingMouth);

      // Motion blur: wajah dan tangan sama-sama hilang, masih dalam tenggang.
      for (int i = 1; i <= 5; i++) {
        now = now.add(const Duration(milliseconds: 200));
        sequence.update(
          handVisible: false,
          faceVisible: false,
          handMouthDistance: null,
          now: now,
          faceLostWithinGrace: true,
        );
      }
      expect(sequence.stage, DrinkingStage.approachingMouth);

      now = now.add(const Duration(milliseconds: 200));
      expect(
        sequence.update(
          handVisible: true,
          faceVisible: true,
          handMouthDistance: 0.18,
          now: now,
        ),
        DrinkingStage.nearMouth,
      );
    });

    test('tahap awal tetap direset bila wajah hilang melewati tenggang', () {
      final DrinkingSequenceMachine sequence = machine();
      DateTime now = t0;

      sequence.update(
        handVisible: true,
        faceVisible: true,
        handMouthDistance: 0.50,
        now: now,
      );
      expect(sequence.stage, DrinkingStage.handWithMedicine);

      now = now.add(const Duration(seconds: 6));
      sequence.update(
        handVisible: false,
        faceVisible: false,
        handMouthDistance: null,
        now: now,
      );
      expect(sequence.stage, DrinkingStage.waiting);
      expect(sequence.maxStageReached, DrinkingStage.handWithMedicine);
    });
  });
}
