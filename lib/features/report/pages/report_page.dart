import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_bottom_nav_bar.dart';
import '../../../shared/widgets/sitara_top_bar.dart';

import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../widgets/report_notice_card.dart';
import '../widgets/report_title_section.dart';
import '../widgets/report_symptom_card.dart';
import '../widgets/report_notes_field.dart';
import '../widgets/report_submit_button.dart';
import '../widgets/report_history_section.dart';

import '../../home/pages/home_page.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';
import '../../progress/models/my_treatment.dart';
import '../../progress/pages/progress_page.dart';
import '../../progress/services/treatment_service.dart';
import '../../medicine/pages/medicine_page.dart';
import '../../profile/pages/profile_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({
    super.key,
    this.highlightedComplaintId,
  });

  /// `complaint_id` dari `notification.reference_id`.
  ///
  /// Dicocokkan dengan hasil `GET /complaints/my`. Null bila halaman dibuka
  /// dari tombol lapor di beranda.
  final int? highlightedComplaintId;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController notesController = TextEditingController();

  final List<String> symptoms = [
    "Mual / Muntah",
    "Pusing",
    "Kulit Ruam / Gatal",
    "Nyeri Sendi",
    "Batuk Berdarah",
    "Lainnya",
  ];

  final List<IconData> icons = [
    Icons.sick_outlined,
    Icons.psychology_outlined,
    Icons.coronavirus_outlined,
    Icons.accessibility_new_outlined,
    Icons.priority_high,
    Icons.more_horiz,
  ];

  final Set<int> selectedSymptoms = {};

  final AuthService _authService = AuthService();
  final ComplaintService _complaintService = ComplaintService();
  final TreatmentService _treatmentService = TreatmentService();

  List<Complaint> _complaints = <Complaint>[];
  bool _isLoadingComplaints = true;
  String? _complaintError;
  bool _didRetryHighlight = false;

  List<MyTreatment> _treatments = <MyTreatment>[];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Dipanggil sekali di sini, bukan di build(), agar tidak ada request
    // berulang setiap kali widget di-rebuild.
    _loadComplaints();
    _loadTreatments();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoadingComplaints = true;
      _complaintError = null;
    });

    try {
      final List<Complaint> complaints =
          await _complaintService.getMyComplaints();

      if (!mounted) return;

      setState(() {
        _complaints = complaints;
        _complaintError = null;
        _isLoadingComplaints = false;
      });

      await _retryHighlightIfMissing();
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _complaints = <Complaint>[];
        _complaintError = error.message;
        _isLoadingComplaints = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _complaints = <Complaint>[];
        _complaintError = ApiException.unexpectedMessage;
        _isLoadingComplaints = false;
      });
    }
  }

  /// Satu penyegaran tambahan lewat `GET /complaints/my` bila id dari
  /// notifikasi belum ada di daftar. Tidak mengarang keluhan.
  Future<void> _retryHighlightIfMissing() async {
    final int? highlightedId = widget.highlightedComplaintId;
    if (highlightedId == null || highlightedId <= 0) return;
    if (_didRetryHighlight) return;
    if (Complaint.findById(_complaints, highlightedId) != null) return;

    _didRetryHighlight = true;
    await _loadComplaints();
  }

  List<Complaint> get _visibleComplaints {
    final Complaint? highlighted = Complaint.findById(
      _complaints,
      widget.highlightedComplaintId,
    );
    if (highlighted == null) return _complaints;
    return <Complaint>[
      highlighted,
      ..._complaints.where((Complaint item) => item.id != highlighted.id),
    ];
  }

  /// Dipakai hanya untuk memperoleh `treatment_id` milik pasien saat mengirim
  /// keluhan. Tidak ada bagian UI yang menampilkan data pengobatan di sini.
  Future<void> _loadTreatments() async {
    try {
      final List<MyTreatment> treatments =
          await _treatmentService.getMyTreatments();

      if (!mounted) return;

      setState(() {
        _treatments = treatments;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _treatments = <MyTreatment>[];
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _treatments = <MyTreatment>[];
      });
    }
  }

  /// Pengobatan aktif milik pasien, sumber sah `treatment_id`.
  ///
  /// Hanya yang berstatus `active` yang dipakai; bila pasien punya lebih dari
  /// satu, yang tanggal mulainya paling akhir yang dipilih.
  MyTreatment? get _activeTreatment {
    final List<MyTreatment> active = _treatments
        .where((MyTreatment item) => item.isActive)
        .toList();

    return MyTreatment.selectCurrent(active);
  }

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

  /// Keluhan "Lainnya" tidak menjelaskan apa pun tanpa catatan,
  /// jadi catatan menjadi wajib ketika opsi ini dipilih.
  int get _otherSymptomIndex => symptoms.indexOf("Lainnya");

  /// Dicari berdasarkan nama, bukan posisi, agar styling peringatan tetap
  /// menempel pada gejala yang benar bila urutan daftar berubah.
  int get _dangerSymptomIndex => symptoms.indexOf("Batuk Berdarah");

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    final String notes = notesController.text.trim();
    final bool hasSymptom = selectedSymptoms.isNotEmpty;

    if (!hasSymptom && notes.isEmpty) {
      _showMessage(
        "Silakan lengkapi laporan keluhan terlebih dahulu.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (!hasSymptom) {
      _showMessage(
        "Silakan lengkapi semua informasi keluhan.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (selectedSymptoms.contains(_otherSymptomIndex) && notes.isEmpty) {
      _showMessage(
        "Silakan isi detail keluhan terlebih dahulu.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    // `treatment_id` wajib pada ComplaintCreate dan backend menolak dengan 403
    // bila bukan milik pasien yang login, jadi keluhan tidak dikirim sama
    // sekali selama pengobatan aktif belum diketahui.
    final MyTreatment? treatment = _activeTreatment;

    if (treatment == null) {
      _showMessage(
        "Keluhan belum dapat dikirim karena data pengobatan Anda belum tersedia. Hubungi petugas kesehatan.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    // Kategori disusun dari gejala yang benar-benar dipilih pasien. Backend
    // menyimpan category sebagai teks bebas, bukan enum.
    final List<int> selected = selectedSymptoms.toList()..sort();
    final String category =
        selected.map((int index) => symptoms[index]).join(", ");

    final String description =
        notes.isNotEmpty ? notes : "Gejala yang dilaporkan: $category.";

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _complaintService.createComplaint(
        treatmentId: treatment.id,
        category: category,
        description: description,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _resetForm();

      _showMessage(
        "Keluhan berhasil dikirim ke petugas kesehatan.",
        backgroundColor: AppColors.success,
      );

      // Riwayat dimuat ulang dari backend, bukan ditambah secara lokal, agar
      // yang tampil benar-benar data yang tersimpan di server.
      await _loadComplaints();
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

  /// Dibersihkan hanya setelah backend membalas dengan sukses.
  void _resetForm() {
    notesController.clear();

    setState(() {
      selectedSymptoms.clear();
    });
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

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Halaman ini dibuka dari Home, cukup kembali agar tidak
        // ada HomePage ganda di navigation stack.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(),
            ),
          );
        }
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProgressPage(),
          ),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MedicinePage(),
          ),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.contentMaxWidth,
                      ),

                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                          vertical: AppSpacing.lg,
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            SitaraTopBar(
                              title: "Lapor Keluhan",
                              onBack: () {
                                Navigator.pop(context);
                              },
                            ),

                            const SizedBox(height: 28),

                            const ReportNoticeCard(),

                            const SizedBox(height: 28),

                            const ReportTitleSection(),

                            const SizedBox(height: 20),

                            ...List.generate(
                              symptoms.length,
                              (index) => ReportSymptomCard(
                                title: symptoms[index],
                                icon: icons[index],
                                isDanger: index == _dangerSymptomIndex,
                                selected:
                                    selectedSymptoms.contains(index),
                                onTap: () {
                                  setState(() {
                                    if (selectedSymptoms.contains(index)) {
                                      selectedSymptoms.remove(index);
                                    } else {
                                      selectedSymptoms.add(index);
                                    }
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                            ReportNotesField(
                              controller: notesController,
                            ),

                            const SizedBox(height: 32),

                            ReportSubmitButton(
                              onPressed: _submitReport,
                              isLoading: _isSubmitting,
                            ),

                            const SizedBox(height: 32),

                            ReportHistorySection(
                              complaints: _visibleComplaints,
                              highlightedComplaintId:
                                  widget.highlightedComplaintId,
                              isLoading: _isLoadingComplaints,
                              errorMessage: _complaintError,
                              onRetry: _loadComplaints,
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SitaraBottomNavBar(
              currentIndex: 0,
              onTap: _onBottomNavTap,
            ),
          ],
        ),
      ),
    );
  }
}