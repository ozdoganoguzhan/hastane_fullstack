import 'package:flutter/material.dart';
import 'package:hastane_menu/components/brand_logo.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/constants/app_typography.dart';
import 'package:hastane_menu/models/staff_session.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Personel QR kartı — yemekhane girişinde okutulacak kurumsal kimlik kartı.
///
/// Kırmızı degrade çerçeve içinde: Bakanlık logolu başlık, kesikli ayraç,
/// QR kod, personel bilgisi ve geçerlilik rozeti.
class StaffQrView extends StatelessWidget {
  const StaffQrView({super.key, required this.session});

  final StaffSession session;

  @override
  Widget build(BuildContext context) {
    // Degrade çerçeve: dış degrade kutu + 1.6px içeride beyaz kart.
    return Container(
      padding: const EdgeInsets.all(1.6),
      decoration: const BoxDecoration(
        gradient: AppColors.redGradient,
        borderRadius: AppSpacing.borderRadiusXxl,
        boxShadow: AppSpacing.shadowLg,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(AppSpacing.radiusXxl - 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Kart başlığı ─────────────────────────────────────────────
            Row(
              children: [
                const BrandLogo(size: 32),
                AppSpacing.gapH12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'T.C. SAĞLIK BAKANLIĞI',
                        style: AppTypography.overline.copyWith(
                          color: AppColors.red,
                          fontSize: 9.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        AppConfig.hospitalName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textStrong,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  ),
                  child: const Text(
                    'PERSONEL',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapV16,
            const _DashedDivider(),
            AppSpacing.gapV16,
            // ── QR ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(color: AppColors.divider, width: 1.4),
              ),
              child: QrImageView(
                data: session.qrData,
                version: QrVersions.auto,
                size: 196,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textStrong,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            AppSpacing.gapV16,
            // ── Kullanım ipucu (kişisel bilgi GÖSTERİLMEZ) ───────────────
            const Text(
              'Bu kodu yemekhane girişinde okutunuz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
            AppSpacing.gapV12,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  AppSpacing.gapH8,
                  Text(
                    'Geçerli',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kart görünümünü tamamlayan ince kesikli ayraç.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(double.infinity, 1),
      painter: _DashPainter(),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.2;
    const double dash = 5;
    const double gap = 4;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
