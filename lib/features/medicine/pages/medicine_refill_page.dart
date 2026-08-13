import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_medicine_schedule.dart';
import '../models/refill.dart';
import '../services/medicine_schedule_service.dart';
import '../services/refill_service.dart';

import '../widgets/refill_stepper.dart';
import '../widgets/refill_medicine_info_card.dart';
import '../widgets/refill_reason_section.dart';
import '../widgets/refill_quantity_field.dart';
import '../widgets/refill_detail_field.dart';
import '../widgets/refill_confirmation_section.dart';
import '../widgets/refill_submit_button.dart';
import '../widgets/refill_history_section.dart';

import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';
import '../../progress/models/my_treatment.dart';
import '../../progress/services/treatment_service.dart';

/// Pengajuan pesan ulang obat.
///
/// `POST /refills` mewajibkan `treatment_id`, `medicine_id`, `quantity`, dan
/// `reason`. Keempatnya berasal dari backend atau dari input pasien:
/// `treatment_id` dari `GET /treatments/my`, `medicine_id` dari
/// `GET /medicine-schedules/my`, sedangkan `quantity` dan `reason` diisi pasien
/// pada form ini. Riwayat permintaan diambil dari `GET /refills/my`.
class MedicineRefillPage extends StatefulWidget {
  const MedicineRefillPage({super.key});

  @override
  State<MedicineRefillPage> createState() =>
      _MedicineRefillPageState();
}

class _MedicineRefillPageState extends State<MedicineRefillPage> {
  final TextEditingController detailController =
      TextEditingController();

  final AuthService _authService = AuthService();
  final TreatmentService _treatmentService = TreatmentService();
  final MedicineScheduleService _scheduleService = MedicineScheduleService();
  final RefillService _refillService = RefillService();

  MyTreatment? _treatment;
  String? _treatmentError;

  List<MyMedicineSchedule> _schedules = <MyMedicineSchedule>[];
  String? _scheduleError;

  List<Refill> _refills = <Refill>[];
  String? _refillsError;
  bool _isLoadingRefills = true;

  bool _isSubmitting = false;

  /// Menjadi true hanya setelah `POST /refills` mengembalikan data, sehingga
  /// langkah "Selesai" pada stepper tidak pernah menyala tanpa kiriman nyata.
  bool _hasSubmitted = false;

  String? selectedReason;
  int quantity = RefillQuantityField.minQuantity;
  bool isConfirmed = false;

  @override
  void initState() {
    super.initState();
    // Dipanggil sekali di sini, bukan di build(), agar tidak ada request
    // berulang setiap kali widget di-rebuild.
    _loadTreatment();
    _loadSchedules();
    _loadRefills();
  }

  @override
  void dispose() {
    detailController.dispose();
    super.dispose();
  }

  Future<void> _loadTreatment() async {
    try {
      final List<MyTreatment> treatments =
          await _treatmentService.getMyTreatments();

      if (!mounted) return;

      setState(() {
        _treatment = MyTreatment.selectCurrent(treatments);
        _treatmentError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _treatment = null;
        _treatmentError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _treatment = null;
        _treatmentError = ApiException.unexpectedMessage;
      });
    }
  }

  Future<void> _loadSchedules() async {
    try {
      final List<MyMedicineSchedule> schedules =
          await _scheduleService.getMySchedules();

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _scheduleError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _schedules = <MyMedicineSchedule>[];
        _scheduleError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _schedules = <MyMedicineSchedule>[];
        _scheduleError = ApiException.unexpectedMessage;
      });
    }
  }

  /// [silent] dipakai saat menyegarkan daftar setelah kiriman berhasil, karena
  /// indikator kemajuannya sudah tampil pada tombol kirim.
  Future<void> _loadRefills({bool silent = false}) async {
    setState(() {
      if (!silent) _isLoadingRefills = true;
      _refillsError = null;
    });

    try {
      final List<Refill> refills = await _refillService.getMyRefills();

      if (!mounted) return;

      setState(() {
        _refills = refills;
        _refillsError = null;
        _isLoadingRefills = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _refills = <Refill>[];
        _refillsError = error.message;
        _isLoadingRefills = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _refills = <Refill>[];
        _refillsError = ApiException.unexpectedMessage;
        _isLoadingRefills = false;
      });
    }
  }

  /// Obat yang dipesan ulang.
  ///
  /// Pilihannya mengikuti kartu stok pada MedicinePage, yaitu jadwal dengan
  /// sisa proporsional paling sedikit. Jadwal disaring lebih dulu ke pengobatan
  /// aktif agar pasangan `treatment_id` dan `medicine_id` yang dikirim benar
  /// berasal dari satu pengobatan, bukan dari dua pengobatan berbeda.
  MyMedicineSchedule? get _refillSchedule {
    final MyTreatment? treatment = _treatment;

    final List<MyMedicineSchedule> pool = treatment == null
        ? _schedules
        : _schedules
            .where(
              (MyMedicineSchedule item) => item.treatmentId == treatment.id,
            )
            .toList();

    if (pool.isEmpty) return null;

    // selectLowestStock bernilai null ketika tidak ada jadwal yang rasio
    // sisanya dapat dihitung, sehingga jadwal pertama dipakai apa adanya.
    return MyMedicineSchedule.selectLowestStock(pool) ?? pool.first;
  }

  Refill? get _latestRefill => Refill.selectLatest(_refills);

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;

    final String detail = detailController.text.trim();

    // Belum isi & belum centang
    if (detail.isEmpty && !isConfirmed) {
      _showMessage(
        "Silakan isi keterangan dan centang persetujuan terlebih dahulu.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    // Belum isi
    if (detail.isEmpty) {
      _showMessage(
        "Silakan isi keterangan terlebih dahulu.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    // Kurang dari 20 karakter
    if (detail.length < 20) {
      _showMessage(
        "Keterangan minimal 20 karakter.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    // Belum checklist
    if (!isConfirmed) {
      _showMessage(
        "Silakan centang pernyataan persetujuan.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    final MyTreatment? treatment = _treatment;
    if (treatment == null) {
      _showMessage(
        "Pesan ulang belum dapat diajukan karena data pengobatan Anda belum tersedia. Hubungi petugas kesehatan.",
      );
      return;
    }

    final MyMedicineSchedule? schedule = _refillSchedule;
    if (schedule == null) {
      _showMessage(
        "Pesan ulang belum dapat diajukan karena data obat Anda belum tersedia. Hubungi petugas kesehatan.",
      );
      return;
    }

    final String? reason = selectedReason;
    if (reason == null) {
      _showMessage(
        "Silakan pilih alasan pesan ulang terlebih dahulu.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (quantity < RefillQuantityField.minQuantity) {
      _showMessage(
        "Jumlah yang diminta minimal ${RefillQuantityField.minQuantity}.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Refill created = await _refillService.createRefill(
        treatmentId: treatment.id,
        medicineId: schedule.medicineId,
        quantity: quantity,
        reason: reason,
        description: detail,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _hasSubmitted = true;
        _refills = <Refill>[created, ..._refills];
      });

      _resetForm();

      _showMessage(
        "Permintaan pesan ulang berhasil dikirim. Petugas kesehatan akan memverifikasinya.",
        backgroundColor: AppColors.success,
      );

      // Status yang ditampilkan tetap milik backend, jadi daftarnya diambil
      // ulang setelah kiriman berhasil.
      await _loadRefills(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      _showMessage(
        error.message,
        backgroundColor: AppColors.error,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        ApiException.unexpectedMessage,
        backgroundColor: AppColors.error,
      );
    }
  }

  /// Dibersihkan hanya setelah permintaan benar-benar terkirim, supaya isi form
  /// tidak hilang ketika kiriman gagal.
  void _resetForm() {
    detailController.clear();

    setState(() {
      selectedReason = null;
      quantity = RefillQuantityField.minQuantity;
      isConfirmed = false;
    });
  }

  /// Token ditolak backend, sesi tidak bisa dilanjutkan.
  ///
  /// Memakai [AuthService.logout] yang sudah ada agar tidak ada mekanisme
  /// pembersihan token baru.
  Future<void> _handleExpiredSession() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  /// [backgroundColor] dibiarkan null untuk pesan informasi, sehingga tidak
  /// tampil sebagai keberhasilan maupun kegagalan validasi.
  void _showMessage(String message, {Color? backgroundColor}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Pesan Ulang Obat",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  RefillStepper(
                    currentStep: _hasSubmitted ? 3 : 1,
                  ),

                  const SizedBox(height: 28),

                  RefillMedicineInfoCard(
                    schedule: _refillSchedule,
                    latestRefill: _latestRefill,
                    errorMessage: _scheduleError ?? _treatmentError,
                  ),

                  const SizedBox(height: 32),

                  RefillReasonSection(
                    selectedReason: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  RefillQuantityField(
                    quantity: quantity,
                    enabled: !_isSubmitting,
                    onChanged: (value) {
                      setState(() {
                        quantity = value;
                      });
                    },
                  ),

                  const SizedBox(height: 28),

                  RefillDetailField(
                    controller: detailController,
                  ),

                  const SizedBox(height: 32),

                  RefillConfirmationSection(
                    value: isConfirmed,
                    onChanged: (value) {
                      setState(() {
                        isConfirmed = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  RefillSubmitButton(
                    onPressed: _submitRequest,
                    isSubmitting: _isSubmitting,
                  ),

                  const SizedBox(height: 32),

                  RefillHistorySection(
                    refills: _refills,
                    isLoading: _isLoadingRefills,
                    errorMessage: _refillsError,
                    onRetry: _loadRefills,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
