import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_medicine_schedule.dart';
import '../models/refill.dart';
import '../services/medicine_schedule_service.dart';
import '../services/refill_service.dart';

import '../utils/refill_form_validation.dart';
import '../utils/refill_medicine_options.dart';
import '../widgets/refill_medicine_picker.dart';
import '../widgets/refill_reason_section.dart';
import '../widgets/refill_confirmation_section.dart';
import '../widgets/refill_summary_section.dart';
import '../widgets/refill_submit_button.dart';
import '../widgets/refill_history_section.dart';

import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';
import '../../progress/models/my_treatment.dart';
import '../../progress/services/treatment_service.dart';

/// Pengajuan pesan ulang obat.
///
/// `POST /refills` mewajibkan `treatment_id`, `medicine_id`, `quantity`, dan
/// `reason`, dengan satu `medicine_id` per permintaan. `treatment_id` dan
/// `medicine_id` berasal dari obat yang dipilih pasien pada
/// `GET /medicine-schedules/my`, `quantity` selalu
/// [RefillFormValidation.fixedQuantity], dan `reason` dipilih pasien di form
/// ini. Riwayat permintaan diambil dari `GET /refills/my`.
class MedicineRefillPage extends StatefulWidget {
  const MedicineRefillPage({
    super.key,
    this.highlightedRefillId,
    this.treatmentService,
    this.scheduleService,
    this.refillService,
  });

  /// `refill_id` dari `notification.reference_id`, dicocokkan dengan
  /// `GET /refills/my`. Null bila halaman dibuka dari tombol pesan ulang.
  final int? highlightedRefillId;

  /// Disuntikkan hanya oleh test, mengikuti pola pada ProgressPage. Null
  /// berarti aplikasi memakai service biasa di atas [ApiClient.instance].
  final TreatmentService? treatmentService;
  final MedicineScheduleService? scheduleService;
  final RefillService? refillService;

  @override
  State<MedicineRefillPage> createState() =>
      _MedicineRefillPageState();
}

class _MedicineRefillPageState extends State<MedicineRefillPage> {
  final AuthService _authService = AuthService();
  late final TreatmentService _treatmentService =
      widget.treatmentService ?? TreatmentService();
  late final MedicineScheduleService _scheduleService =
      widget.scheduleService ?? MedicineScheduleService();
  late final RefillService _refillService =
      widget.refillService ?? RefillService();

  MyTreatment? _treatment;
  String? _treatmentError;

  List<MyMedicineSchedule> _schedules = <MyMedicineSchedule>[];
  String? _scheduleError;
  bool _isLoadingSchedules = true;

  List<Refill> _refills = <Refill>[];
  String? _refillsError;
  bool _isLoadingRefills = true;
  /// Terpisah dari [_isLoadingRefills]: flag UI mulai `true` agar spinner
  /// tampil pada frame pertama, tetapi tidak boleh memblokir fetch awal.
  bool _isFetchingRefills = false;

  final RefillSubmitLock _submitLock = RefillSubmitLock();
  final GlobalKey _formKey = GlobalKey();

  String? selectedReason;
  bool isConfirmed = false;

  /// Satu obat per permintaan, sesuai `RefillCreate` yang hanya menerima satu
  /// `medicine_id`.
  MyMedicineSchedule? _selectedMedicine;

  @override
  void initState() {
    super.initState();
    // Dipanggil sekali di sini, bukan di build(), agar tidak ada request
    // berulang setiap kali widget di-rebuild.
    _loadTreatment();
    _loadSchedules();
    _loadRefills();
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
      // Daftar pilihan disaring ke pengobatan aktif, jadi pilihan disegarkan
      // lagi setelah data pengobatan tiba.
      _syncSelectionWithOptions();
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
        _isLoadingSchedules = false;
      });
      _syncSelectionWithOptions();
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _schedules = <MyMedicineSchedule>[];
        _scheduleError = error.message;
        _isLoadingSchedules = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _schedules = <MyMedicineSchedule>[];
        _scheduleError = ApiException.unexpectedMessage;
        _isLoadingSchedules = false;
      });
    }
  }

  /// Menyelaraskan pilihan dengan daftar obat pasien.
  ///
  /// Pasien dengan satu jenis obat tidak perlu memilih: satu-satunya pilihan
  /// yang valid langsung dipakai. Pilihan yang tidak lagi ada pada jadwal
  /// dikosongkan, supaya `medicine_id` di luar jadwal pasien tidak terkirim.
  void _syncSelectionWithOptions() {
    if (!mounted) return;

    final List<MyMedicineSchedule> options = _medicineOptions;
    final MyMedicineSchedule? selected = _selectedMedicine;

    if (selected != null &&
        !options.any(
          (MyMedicineSchedule item) => item.medicineId == selected.medicineId,
        )) {
      setState(() => _selectedMedicine = null);
    }

    if (options.length == 1 &&
        _selectedMedicine?.medicineId != options.first.medicineId) {
      setState(() => _selectedMedicine = options.first);
    }
  }

  /// [silent] dipakai saat menyegarkan daftar setelah kiriman berhasil, karena
  /// indikator kemajuannya sudah tampil pada tombol kirim.
  Future<void> _loadRefills({bool silent = false}) async {
    if (RefillHistoryFetch.skipDuplicate(inFlight: _isFetchingRefills)) {
      return;
    }
    _isFetchingRefills = true;

    // Jangan setState di sini pada fetch awal: [_isLoadingRefills] sudah true
    // dari initState, dan setState sinkron sebelum await tidak diizinkan.
    if (!silent && !_isLoadingRefills && mounted) {
      setState(() {
        _isLoadingRefills = true;
        _refillsError = null;
      });
    } else if (silent && _refills.isEmpty && mounted) {
      setState(() => _refillsError = null);
    }

    try {
      debugPrint('[Refill] fetch start');
      debugPrint('[Refill] GET /refills/my');

      final List<Refill> refills = await _refillService.getMyRefills();
      debugPrint('[Refill] response received');

      if (!mounted) return;

      setState(() {
        _refills = refills;
        _refillsError = null;
      });
    } on ApiException catch (error) {
      debugPrint('[Refill] error');
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      _handleRefillsFailure(error.message, silent: silent);
    } catch (_) {
      debugPrint('[Refill] error');
      if (!mounted) return;
      _handleRefillsFailure(ApiException.unexpectedMessage, silent: silent);
    } finally {
      _isFetchingRefills = false;
      if (mounted && _isLoadingRefills) {
        setState(() => _isLoadingRefills = false);
      }
    }
  }

  void _handleRefillsFailure(String message, {required bool silent}) {
    if (silent && _refills.isNotEmpty) {
      _showMessage(message, backgroundColor: AppColors.error);
      return;
    }

    setState(() => _refillsError = message);
  }

  /// Jenis obat yang boleh dipesan ulang.
  ///
  /// Hanya obat pada jadwal milik pasien yang sedang login, hasil
  /// `GET /medicine-schedules/my`. Jadwal disaring lebih dulu ke pengobatan
  /// aktif agar pasangan `treatment_id` dan `medicine_id` yang dikirim berasal
  /// dari satu pengobatan, bukan dari dua pengobatan berbeda. Satu obat dengan
  /// beberapa jam minum tetap muncul satu kali.
  List<MyMedicineSchedule> get _medicineOptions {
    return RefillMedicineOptions.fromSchedules(
      _schedules,
      treatmentId: _treatment?.id,
    );
  }

  bool get _canSubmit {
    if (_submitLock.isLocked) return false;
    return RefillFormValidation.canSubmitSingle(
      hasTreatment: _treatment != null,
      hasMedicine: _selectedMedicine != null,
      reason: selectedReason,
      confirmed: isConfirmed,
    );
  }

  Future<void> _submitRequest() async {
    final String? validationError = RefillFormValidation.validateSingle(
      hasTreatment: _treatment != null,
      hasMedicine: _selectedMedicine != null,
      reason: selectedReason,
      confirmed: isConfirmed,
    );
    if (validationError != null) {
      _showMessage(
        validationError,
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (!_submitLock.tryLock()) return;
    setState(() {});

    final MyMedicineSchedule medicine = _selectedMedicine!;
    final String reason = selectedReason!;

    try {
      // Satu permintaan untuk satu obat. Obat lain memerlukan permintaan baru.
      final Refill created = await _refillService.createRefill(
        treatmentId: medicine.treatmentId,
        medicineId: medicine.medicineId,
        quantity: RefillFormValidation.fixedQuantity,
        reason: reason,
      );

      if (!mounted) return;

      setState(() {
        _refills = <Refill>[created, ..._refills];
      });

      _resetForm();

      _showMessage(
        "Permintaan pesan ulang berhasil dikirim. Petugas kesehatan akan memverifikasinya.",
        backgroundColor: AppColors.success,
      );

      await _loadRefills(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;

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

      _showMessage(
        ApiException.unexpectedMessage,
        backgroundColor: AppColors.error,
      );
    } finally {
      _submitLock.unlock();
      if (mounted) setState(() {});
    }
  }

  /// Dibersihkan hanya setelah permintaan benar-benar terkirim, supaya isi form
  /// tidak hilang ketika kiriman gagal.
  void _resetForm() {
    setState(() {
      selectedReason = null;
      isConfirmed = false;
      _selectedMedicine = null;
    });
    // Pasien dengan satu jenis obat tetap terisi otomatis setelah form bersih.
    _syncSelectionWithOptions();
  }

  void _scrollToForm() {
    final BuildContext? target = _formKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0,
    );
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

                  KeyedSubtree(
                    key: _formKey,
                    child: RefillMedicinePicker(
                      options: _medicineOptions,
                      selected: _selectedMedicine,
                      isLoading: _isLoadingSchedules,
                      errorMessage: _scheduleError ?? _treatmentError,
                      enabled: !_submitLock.isLocked,
                      onSelected: (MyMedicineSchedule? value) {
                        setState(() => _selectedMedicine = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  RefillReasonSection(
                    selectedReason: selectedReason,
                    onChanged: _submitLock.isLocked
                        ? (_) {}
                        : (value) {
                            setState(() {
                              selectedReason = value;
                            });
                          },
                  ),

                  const SizedBox(height: 28),

                  RefillSummarySection(
                    medicineName: _selectedMedicine?.displayName,
                    quantity: RefillFormValidation.fixedQuantity,
                    reason: selectedReason,
                  ),

                  const SizedBox(height: 32),

                  RefillConfirmationSection(
                    value: isConfirmed,
                    onChanged: _submitLock.isLocked
                        ? (_) {}
                        : (value) {
                            setState(() {
                              isConfirmed = value;
                            });
                          },
                  ),

                  const SizedBox(height: 20),

                  RefillSubmitButton(
                    onPressed: _canSubmit ? _submitRequest : null,
                    isSubmitting: _submitLock.isLocked,
                  ),

                  const SizedBox(height: 32),

                  RefillHistorySection(
                    refills: _refills,
                    schedules: _schedules,
                    highlightedRefillId: widget.highlightedRefillId,
                    isLoading: _isLoadingRefills,
                    errorMessage: _refillsError,
                    onRetry: _loadRefills,
                    onStartRequest: _scrollToForm,
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
