import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hastane_menu/components/app_button.dart';
import 'package:hastane_menu/components/brand_logo.dart';
import 'package:hastane_menu/components/otp_input.dart';
import 'package:hastane_menu/components/segmented_tabs.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_config.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/auth_service.dart';

/// Giriş yöntemi seçimi.
enum _Method { phone, credentials }

/// Telefon yönteminin alt adımı.
enum _PhoneStep { input, otp }

/// Tam ekran giriş kapısı — kurumsal degrade hero + Bakanlık logosu +
/// hero üzerine bindirilmiş giriş kartı.
///
/// Uygulamaya yalnızca giriş yapıldıktan sonra erişilir (bkz. `AuthGate`).
/// İki giriş yöntemi sunar:
///  1. **Telefon** → 6 haneli SMS kodu (2FA) — `AuthService.requestOtp/verifyOtp`.
///  2. **Kullanıcı adı + şifre** → demo girişi (bkz. `AppConfig.demoUsername` /
///     `AppConfig.demoPassword`) —
///     `AuthService.loginWithCredentials`; demo oturumunda dummy data gösterilir.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.demoOnly = false, this.onBack});

  /// `true` ise yalnızca kullanıcı adı/şifre (demo) yöntemi gösterilir.
  /// Ağ kapısı kapalıyken telefon akışı zaten HBYS'ye ulaşamaz — kullanıcıyı
  /// çalışmayacak bir yola sokmamak için sekme gizlenir.
  final bool demoOnly;

  /// [demoOnly] modunda engelleme ekranına dönüş. `null` ise geri yolu yoktur.
  final VoidCallback? onBack;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = $get<AuthService>();
  final SessionState _sessionState = $get<SessionState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _Method _method = _Method.phone;
  _PhoneStep _phoneStep = _PhoneStep.input;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String _code = '';

  @override
  void initState() {
    super.initState();
    // Demo-only modda telefon sekmesi yok; doğrudan kullanıcı adı formu açılır.
    if (widget.demoOnly) _method = _Method.credentials;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();

  void _switchMethod(_Method method) {
    if (_method == method || _loading) return;
    setState(() {
      _method = method;
      _error = null;
    });
  }

  // ── Telefon akışı ────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.requestOtp(_phone);
      setState(() {
        _phoneStep = _PhoneStep.otp;
        _code = '';
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _auth.verifyOtp(phone: _phone, code: _code);
      _sessionState.setSession(session);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Kullanıcı adı / şifre akışı ──────────────────────────────────────────
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _auth.loginWithCredentials(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      _sessionState.setSession(session);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Kurumsal degrade hero (arka plan) ─────────────────────────
          _HeroBackdrop(height: topInset + 316),
          // ── İçerik ────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              child: Column(
                children: [
                  const _Brand(),
                  AppSpacing.gapV24,
                  // Giriş kartı — hero'nun alt kenarına bindirilir.
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppSpacing.borderRadiusXxl,
                      boxShadow: AppSpacing.shadowLg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.demoOnly)
                          const _DemoNotice()
                        else
                          SegmentedTabs(
                            items: const [
                              SegmentedItem('Telefon', icon: Icons.sms_rounded),
                              SegmentedItem(
                                'Kullanıcı Adı',
                                icon: Icons.badge_rounded,
                              ),
                            ],
                            current: _method.index,
                            onChanged: (i) => _switchMethod(_Method.values[i]),
                          ),
                        AppSpacing.gapV24,
                        AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: _method == _Method.phone
                                ? _phoneForm()
                                : _credentialsForm(),
                          ),
                        ),
                        if (_error != null) _ErrorBanner(_error!),
                        if (widget.onBack != null) ...[
                          AppSpacing.gapV8,
                          TextButton.icon(
                            onPressed: _loading ? null : widget.onBack,
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            label: const Text('Ağ kontrolüne dön'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.gapV24,
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form: Telefon ──────────────────────────────────────────────────────
  Widget _phoneForm() {
    if (_phoneStep == _PhoneStep.otp) {
      return Column(
        key: const ValueKey('otp'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Telefonunuza gönderilen 6 haneli kodu girin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textLight,
            ),
          ),
          AppSpacing.gapV20,
          OtpInput(
            hasError: _error != null,
            onChanged: (v) => setState(() {
              _code = v;
              _error = null;
            }),
            onCompleted: (v) {
              _code = v;
              _verifyOtp();
            },
          ),
          AppSpacing.gapV20,
          AppButton(
            label: 'Doğrula ve Giriş Yap',
            loading: _loading,
            onPressed: _code.length == 6 ? _verifyOtp : null,
          ),
          AppSpacing.gapV8,
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                    _phoneStep = _PhoneStep.input;
                    _error = null;
                  }),
            child: const Text('Numarayı değiştir'),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() => _error = null),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: const InputDecoration(
            labelText: 'Telefon Numarası',
            hintText: '5XX XXX XX XX',
            prefixText: '+90  ',
            prefixIcon: Icon(Icons.phone_rounded, size: 20),
            prefixStyle: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppSpacing.gapV20,
        AppButton(
          label: 'Kod Gönder',
          icon: Icons.sms_rounded,
          loading: _loading,
          onPressed: _phone.length >= 10 ? _sendOtp : null,
        ),
      ],
    );
  }

  // ── Form: Kullanıcı adı / şifre ────────────────────────────────────────
  Widget _credentialsForm() {
    return Column(
      key: const ValueKey('credentials'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _usernameController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(
            labelText: 'Kullanıcı Adı',
            hintText: 'kullanıcı adınız',
            prefixIcon: Icon(Icons.person_rounded, size: 20),
          ),
        ),
        AppSpacing.gapV16,
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            labelText: 'Şifre',
            hintText: '••••••',
            prefixIcon: const Icon(Icons.lock_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        AppSpacing.gapV20,
        AppButton(
          label: 'Giriş Yap',
          icon: Icons.login_rounded,
          loading: _loading,
          onPressed:
              (_usernameController.text.trim().isNotEmpty &&
                  _passwordController.text.isNotEmpty)
              ? _login
              : null,
        ),
      ],
    );
  }
}

// ── Hero arka planı ────────────────────────────────────────────────────────
class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusHero + 4),
        ),
        boxShadow: AppSpacing.shadowHero,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -20,
            child: BrandLogo(
              size: 240,
              color: AppColors.white.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Marka başlığı ──────────────────────────────────────────────────────────
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandLogoTile(size: 92, circular: true),
        AppSpacing.gapV16,
        const Text(
          AppConfig.hospitalName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppConfig.appSubtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.white.withValues(alpha: 0.8),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Alt marka satırı ───────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BrandLogo(size: 16),
        AppSpacing.gapH8,
        Text(
          'T.C. Sağlık Bakanlığı • ${AppConfig.appSubtitle}',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ── Hata bandı ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.base),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: AppColors.error,
          ),
          AppSpacing.gapH8,
          Expanded(
            child: Text(
              message,
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
    );
  }
}

// ── Demo-only modu bilgilendirmesi ─────────────────────────────────────────
/// Ağ kapısı dışında açılan giriş kartının başlığı — kullanıcının gerçek
/// hastane verisi göreceğini sanmaması için.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_rounded, size: 18, color: AppColors.warning),
          AppSpacing.gapH8,
          const Expanded(
            child: Text(
              'Hastane ağı dışındasınız. Test hesabıyla giriş yapabilirsiniz; '
              'gösterilen içerik örnek veridir.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
