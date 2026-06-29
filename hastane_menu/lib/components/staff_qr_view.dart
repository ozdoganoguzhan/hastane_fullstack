import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/models/staff_session.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Personel QR kartı — yemekhane girişinde okutulacak kod.
class StaffQrView extends StatelessWidget {
  const StaffQrView({super.key, required this.session});

  final StaffSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppSpacing.borderRadiusXl,
            border: Border.all(color: AppColors.border),
            boxShadow: AppSpacing.shadow,
          ),
          child: QrImageView(
            data: session.qrData,
            version: QrVersions.auto,
            size: 220,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.text,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.text,
            ),
          ),
        ),
        AppSpacing.gapV16,
        Text(
          session.fullName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${session.title} • ${session.maskedPhone}',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        AppSpacing.gapV12,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              AppSpacing.gapH8,
              Text(
                'Geçerli • ${session.qrData}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
