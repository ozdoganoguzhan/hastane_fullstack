import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';

/// T.C. Sağlık Bakanlığı logosu (`assets/logo-tr.png`) için tek giriş noktası.
///
/// - [BrandLogo]     → çıplak logo; [color] verilirse tek renge boyanır
///   (kırmızı degrade üzerinde beyaz filigran için `white.withValues(...)`).
/// - [BrandLogoTile] → beyaz yuvarlatılmış kutu içinde logo; hero başlıklar,
///   giriş ekranı ve kartlarda kullanılan kurumsal rozet hâlidir.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40, this.color});

  /// Logonun kenar uzunluğu (kare).
  final double size;

  /// Verilirse logo bu renge boyanır (filigran/tek renk kullanım).
  final Color? color;

  static const String _asset = 'assets/logo-tr.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      color: color,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}

/// Beyaz zemin üzerinde gölgeli logo kutusu — kurumsal marka rozeti.
class BrandLogoTile extends StatelessWidget {
  const BrandLogoTile({
    super.key,
    this.size = 48,
    this.circular = false,
    this.elevated = true,
  });

  /// Kutunun dış kenar uzunluğu; logo içeride orantılı küçülür.
  final double size;

  /// `true` → tam daire, `false` → yuvarlatılmış kare.
  final bool circular;

  /// `false` → gölgesiz (renkli zeminlerde kenar çizgisi yeterlidir).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular
            ? null
            : BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppColors.divider),
        boxShadow: elevated ? AppSpacing.shadow : null,
      ),
      child: BrandLogo(size: size * 0.68),
    );
  }
}
