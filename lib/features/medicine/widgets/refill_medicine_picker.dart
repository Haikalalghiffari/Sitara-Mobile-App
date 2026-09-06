import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_medicine_schedule.dart';
import '../utils/refill_form_validation.dart';
import '../utils/refill_medicine_options.dart';

/// Pemilihan obat yang ingin dipesan ulang.
///
/// Satu permintaan hanya untuk satu obat, sesuai `RefillCreate` yang menerima
/// satu `medicine_id`. Daftar pilihannya berasal dari
/// `GET /medicine-schedules/my`, bukan daftar statis di aplikasi.
class RefillMedicinePicker extends StatelessWidget {
  const RefillMedicinePicker({
    super.key,
    this.options = const <MyMedicineSchedule>[],
    this.selected,
    required this.onSelected,
    this.isLoading = false,
    this.errorMessage,
    this.enabled = true,
  });

  final List<MyMedicineSchedule> options;

  /// Obat yang sedang dipilih. Null berarti pasien belum memilih.
  final MyMedicineSchedule? selected;

  /// Dipanggil dengan obat baru, atau null saat pilihan dikosongkan.
  final ValueChanged<MyMedicineSchedule?> onSelected;

  final bool isLoading;
  final String? errorMessage;
  final bool enabled;

  /// Judul saat pasien punya lebih dari satu jenis obat dan harus memilih.
  static const String title = 'Obat yang ingin dipesan';

  /// Judul saat hanya ada satu jenis obat, sehingga tidak ada yang dipilih.
  static const String singleOptionTitle = 'Obat';

  static const String placeholder = 'Pilih obat';
  static const String loadingLabel = 'Memuat daftar obat...';
  static const String emptyLabel = 'Data obat belum tersedia';
  static const String searchHint = 'Cari nama obat';
  static const String noMatchLabel = 'Obat tidak ditemukan.';

  /// Informasi jumlah, hanya untuk dibaca.
  static const String quantityInfo =
      'Jumlah: ${RefillFormValidation.fixedQuantity} untuk setiap permintaan. '
      'Ditetapkan sistem dan tidak dapat diubah.';

  /// Satu jenis obat berarti tidak ada yang perlu dipilih: obatnya ditampilkan
  /// langsung, tanpa dropdown dan tanpa pencarian.
  bool get hasSingleOption => options.length == 1;

  bool get _canOpen => enabled && !isLoading && options.length > 1;

  @override
  Widget build(BuildContext context) {
    // Dengan satu jenis obat, obat itulah yang ditampilkan meski pasien belum
    // menyentuh apa pun.
    final MyMedicineSchedule? item =
        selected ?? (hasSingleOption ? options.first : null);
    final String? helper = _helperText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasSingleOption ? singleOptionTitle : title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 18),

        InkWell(
          borderRadius: AppRadius.card,
          onTap: _canOpen ? () => _openPicker(context) : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              border: Border.all(
                color: item != null
                    ? AppColors.primary
                    : AppColors.outlineVariant,
                width: item != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medication_outlined,
                  color: _canOpen || item != null
                      ? AppColors.primary
                      : AppColors.textDisabled,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.displayName ??
                            (isLoading
                                ? loadingLabel
                                : (options.isEmpty
                                    ? emptyLabel
                                    : placeholder)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: item != null
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: item != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                      ),
                      if (item != null && item.dosage.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.dosage.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasSingleOption)
                  // Tidak ada kontrol: tidak ada pilihan lain yang valid.
                  const SizedBox.shrink()
                else if (item != null)
                  // Mengosongkan pilihan agar pasien dapat menggantinya
                  // sebelum permintaan dikirim.
                  IconButton(
                    tooltip: 'Hapus pilihan obat',
                    onPressed: enabled ? () => onSelected(null) : null,
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Icon(
                    Icons.arrow_drop_down,
                    color: _canOpen
                        ? AppColors.textSecondary
                        : AppColors.textDisabled,
                  ),
              ],
            ),
          ),
        ),

        if (helper != null) ...[
          const SizedBox(height: 10),
          Text(
            helper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: errorMessage != null
                      ? AppColors.error
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],

        const SizedBox(height: 10),

        Text(
          quantityInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
        ),
      ],
    );
  }

  String? _helperText() {
    if (isLoading) return null;
    final String? error = errorMessage;
    if (error != null && error.trim().isNotEmpty) return error;
    if (options.isEmpty) {
      return 'Pilihan obat akan muncul setelah petugas kesehatan melengkapi '
          'jadwal obat Anda.';
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    final MyMedicineSchedule? picked =
        await showModalBottomSheet<MyMedicineSchedule>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return _MedicinePickerSheet(
          options: options,
          selectedMedicineId: selected?.medicineId,
        );
      },
    );

    if (picked == null) return;
    onSelected(picked);
  }
}

/// Daftar obat dengan pencarian. Pencarian menyaring data yang sudah diambil,
/// tidak memicu request baru.
class _MedicinePickerSheet extends StatefulWidget {
  const _MedicinePickerSheet({
    required this.options,
    this.selectedMedicineId,
  });

  final List<MyMedicineSchedule> options;
  final int? selectedMedicineId;

  @override
  State<_MedicinePickerSheet> createState() => _MedicinePickerSheetState();
}

class _MedicinePickerSheetState extends State<_MedicinePickerSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<MyMedicineSchedule> results = RefillMedicineOptions.search(
      widget.options,
      _query,
    );

    return Padding(
      // Menaikkan isi sheet saat papan ketik pencarian muncul.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),

              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RefillMedicinePicker.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onChanged: (String value) {
                        setState(() => _query = value);
                      },
                      decoration: InputDecoration(
                        hintText: RefillMedicinePicker.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.component,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          RefillMedicinePicker.noMatchLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final MyMedicineSchedule item = results[index];
                          final bool isSelected =
                              item.medicineId == widget.selectedMedicineId;

                          return ListTile(
                            onTap: () => Navigator.pop(context, item),
                            title: Text(
                              item.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                            ),
                            subtitle: item.dosage.trim().isEmpty
                                ? null
                                : Text(
                                    item.dosage.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                          );
                        },
                      ),
              ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
