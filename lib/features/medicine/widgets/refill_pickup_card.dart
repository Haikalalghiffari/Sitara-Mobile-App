import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/external_link.dart';

import '../models/refill.dart';

/// Informasi lokasi pengambilan obat untuk permintaan yang sudah disetujui.
///
/// Datanya berasal dari `pickup_facility` pada `GET /refills/my`. Backend tidak
/// mengirim tanggal maupun jam pengambilan, jadi kartu ini tidak menampilkan
/// jadwal. `approved_at` adalah waktu persetujuan dan tidak dipakai di sini.
class RefillPickupCard extends StatelessWidget {
  const RefillPickupCard({
    super.key,
    required this.facility,
    this.openExternalUrl,
  });

  final PickupFacility facility;

  /// Dapat diganti pada pengujian. Default memakai [ExternalLink.open].
  final ExternalUrlOpener? openExternalUrl;

  static const String unavailableAddress =
      'Alamat fasilitas belum tersedia dari petugas.';

  static const String openFailedMessage =
      'Google Maps tidak dapat dibuka di perangkat ini.';

  Future<void> _openMaps(BuildContext context) async {
    final Uri? url = facility.mapsUri;
    if (url == null) return;

    final ExternalUrlOpener opener = openExternalUrl ?? ExternalLink.open;
    final bool opened = await opener(url);
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(openFailedMessage),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? name = facility.nameText;
    final String? address = facility.addressText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingSmall),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_pharmacy_outlined,
                size: 20,
                color: AppColors.primary,
              ),

              const SizedBox(width: 8),

              Text(
                "Pengambilan Obat",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "Nama faskes",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

          const SizedBox(height: 2),

          Text(
            name ?? "",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
          ),

          const SizedBox(height: 10),

          Text(
            "Alamat",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

          const SizedBox(height: 2),

          Text(
            address ?? unavailableAddress,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: address == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  height: 1.4,
                ),
          ),

          // Tombol hanya ada bila backend mengirim latitude dan longitude.
          if (facility.hasCoordinates) ...[
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openMaps(context),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text("Buka Maps"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
