import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hastane_menu/components/otp_input.dart';
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

/// Tam ekran giriş kapısı.
///
/// Uygulamaya yalnızca giriş yapıldıktan sonra erişilir (bkz. `AuthGate`).
/// İki giriş yöntemi sunar:
///  1. **Telefon** → 6 haneli SMS kodu (2FA) — `AuthService.requestOtp/verifyOtp`.
///  2. **Kullanıcı adı + şifre** → demo girişi (`test` / `12345`) —
///     `AuthService.loginWithCredentials`; demo oturumunda dummy data gösterilir.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            children: [
              const _Brand(),
              AppSpacing.gapV32,
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppSpacing.borderRadiusLg,
                  boxShadow: AppSpacing.shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MethodToggle(
                      method: _method,
                      onChanged: _switchMethod,
                    ),
                    AppSpacing.gapV24,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _method == _Method.phone
                          ? _phoneForm()
                          : _credentialsForm(),
                    ),
                    if (_error != null) _ErrorText(_error!),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          Text(
            '+90 $_phone numarasına gönderilen 6 haneli kodu girin.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
          _PrimaryButton(
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
            child: const Text(
              'Numarayı değiştir',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          controller: _phoneController,
          label: 'Telefon Numarası',
          hint: '5XX XXX XX XX',
          prefixText: '+90  ',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() => _error = null),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        AppSpacing.gapV20,
        _PrimaryButton(
          label: 'Kod Gönder',
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
        _Field(
          controller: _usernameController,
          label: 'Kullanıcı Adı',
          hint: 'kullanıcı adınız',
          icon: Icons.person_rounded,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _error = null),
        ),
        AppSpacing.gapV16,
        _Field(
          controller: _passwordController,
          label: 'Şifre',
          hint: '••••••',
          icon: Icons.lock_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _login(),
          suffix: IconButton(
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
        AppSpacing.gapV20,
        _PrimaryButton(
          label: 'Giriş Yap',
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

// ── Marka başlığı ──────────────────────────────────────────────────────────
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            gradient: AppColors.redGradient,
            shape: BoxShape.circle,
            boxShadow: AppSpacing.shadowLg,
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.white,
            size: 38,
          ),
        ),
        AppSpacing.gapV16,
        Text(
          AppConfig.hospitalName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppConfig.appSubtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
      ],
    );
  }
}

// ── Yöntem seçici (segmented) ────────────────────────────────────────────
class _MethodToggle extends StatelessWidget {
  const _MethodToggle({required this.method, required this.onChanged});

  final _Method method;
  final ValueChanged<_Method> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          _segment('Telefon', Icons.sms_rounded, _Method.phone),
          _segment('Kullanıcı Adı', Icons.badge_rounded, _Method.credentials),
        ],
      ),
    );
  }

  Widget _segment(String label, IconData icon, _Method value) {
    final selected = method == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusSm,
            boxShadow: selected ? AppSpacing.shadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.red : AppColors.textLight,
              ),
              AppSpacing.gapH8,
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.text : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ortak metin alanı ──────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.prefixText,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? prefixText;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffix,
        prefixStyle: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.red, 1.5),
      ),
    );
  }
}

// ── Birincil buton ─────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

// ── Hata satırı ────────────────────────────────────────────────────────────
class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          AppSpacing.gapH8,
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
