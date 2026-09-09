import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';

/// Giriş ekranlarındaki hata bandı.
///
/// [diagnostics] verilmiş ve [AppConfig.showErrorDiagnostics] açıksa, mesajın
/// altında **açılıp kapanan bir teknik döküm** gösterir: hangi aşamada patladı,
/// hangi istek, HTTP kodu ne, sunucu ham olarak ne döndü. Yanında kopyala
/// düğmesi vardır — saha ekibi tek dokunuşla panoya alıp iletebilsin.
///
/// Mağaza sürümünde [AppConfig.showErrorDiagnostics] `false`'tur; kullanıcı
/// yalnızca sade mesajı görür.
class ErrorBanner extends StatefulWidget {
  const ErrorBanner(this.message, {super.key, this.diagnostics});

  final String message;
  final String? diagnostics;

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner> {
  bool _open = false;

  bool get _hasDetails =>
      AppConfig.showErrorDiagnostics &&
      (widget.diagnostics?.trim().isNotEmpty ?? false);

  void _copy() {
    Clipboard.setData(
      ClipboardData(text: '${widget.message}\n\n${widget.diagnostics}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hata detayı panoya kopyalandı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.base),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 17,
                color: AppColors.error,
              ),
              AppSpacing.gapH8,
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (_hasDetails) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _open = !_open),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _open
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const Text(
                          'Teknik detay',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _copy,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 15,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Kopyala',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_open)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                // Uzun ham yanıtlar kutuyu taşırmasın: kendi içinde kayar.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.diagnostics!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.45,
                        fontFamily: 'monospace',
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
