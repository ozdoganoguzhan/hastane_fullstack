import 'package:flutter/material.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';

/// Kapari Hazır Yemek logosu (`assets/kapari.png`) için tek giriş noktası.
///
/// ⚠️ Logo **KARE DEĞİLDİR** — yaklaşık 2:1 en/boy oranında bir wordmark'tır
/// (717×348). Bu yüzden ölçü **yükseklikten** verilir, genişlik oranı korunarak
/// kendiliğinden hesaplanır. Logoyu kareye sıkıştırmayın.
///
/// - [BrandLogo]     → çıplak wordmark; [color] verilirse tek renge boyanır
///   (lacivert degrade üzerinde beyaz/filigran kullanım için).
/// - [BrandLogoTile] → beyaz yuvarlatılmış kare rozet içinde wordmark; uygulama
///   ikonuyla aynı görünüm. Hero başlıklar ve kartlarda kullanılır.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 24, this.color});

  /// Logonun YÜKSEKLİĞİ. Genişlik en/boy oranından gelir (≈ height × 2.06).
  final double height;

  /// Verilirse logo bu renge boyanır (filigran/tek renk kullanım).
  final Color? color;

  /// Wordmark'ın en/boy oranı — kaynak görsel 717×348.
  static const double aspectRatio = 717 / 348;

  static const String _asset = 'assets/kapari.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      height: height,
      color: color,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}

/// Beyaz zemin üzerinde gölgeli logo rozeti — uygulama ikonunun ekran içi hâli.
///
/// Wordmark geniş olduğu için rozet **daire yapılmaz**; yuvarlatılmış kare
/// kullanılır ve logo genişliğe göre yerleştirilir.
class BrandLogoTile extends StatelessWidget {
  const BrandLogoTile({super.key, this.size = 48, this.elevated = true});

  /// Rozetin kenar uzunluğu (kare); logo içeride orantılı yerleşir.
  final double size;

  /// `false` → gölgesiz (renkli zeminlerde kenar çizgisi yeterlidir).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: size * 0.12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: AppColors.divider),
        boxShadow: elevated ? AppSpacing.shadow : null,
      ),
      // Kare rozetin içinde okunur kalması için yüksekliği kenarın ~%38'i.
      child: BrandLogo(height: size * 0.38),
    );
  }
}
