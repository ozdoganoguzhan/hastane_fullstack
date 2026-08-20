import 'package:flutter/material.dart';
import 'package:hastane_menu/components/pressable.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';

/// Buton görünümü.
enum AppButtonVariant {
  /// Lacivert degrade + renkli parlama gölgesi — birincil eylem.
  primary,

  /// Açık lacivert zemin + lacivert metin — ikincil eylem.
  soft,
}

/// Uygulamanın standart geniş butonu — degrade zemin, basınç animasyonu ve
/// yükleniyor durumu ile. Giriş/doğrulama/engelleme ekranlarında kullanılır.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final bool primary = variant == AppButtonVariant.primary;

    final Color foreground = _enabled
        ? (primary ? AppColors.white : AppColors.primary)
        : AppColors.textMuted;

    return Pressable(
      onTap: _enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: _enabled && primary ? AppColors.primaryGradient : null,
          color: _enabled
              ? (primary ? null : AppColors.primarySoft)
              : AppColors.border,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppSpacing.radiusMd + 2),
          ),
          boxShadow: _enabled && primary ? AppSpacing.shadowPrimary : null,
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: primary ? AppColors.white : AppColors.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: foreground),
                    AppSpacing.gapH8,
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: foreground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
