import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hastane_menu/components/otp_input.dart';
import 'package:hastane_menu/components/staff_qr_view.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';
import 'package:hastane_menu/core/constants/app_spacing.dart';
import 'package:hastane_menu/core/state/session_state.dart';
import 'package:hastane_menu/core/state/state_manager.dart';
import 'package:hastane_menu/data/auth_service.dart';

enum _Step { phone, otp, qr }

/// Çok adımlı giriş bottom sheet'i: telefon → 6 haneli 2FA → QR kod.
///
/// `LoginSheet.show(context)` ile açılır. Oturum zaten varsa doğrudan QR
/// adımında açılır.
class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const LoginSheet(),
    );
  }

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  final AuthService _auth = $get<AuthService>();
  final SessionState _sessionState = $get<SessionState>();
  final TextEditingController _phoneController = TextEditingController();

  late _Step _step =
      _sessionState.isLoggedIn ? _Step.qr : _Step.phone;
  bool _loading = false;
  String? _error;
  String _code = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.requestOtp(_phone);
      setState(() {
        _step = _Step.otp;
        _code = '';
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _auth.verifyOtp(phone: _phone, code: _code);
      _sessionState.setSession(session);
      setState(() => _step = _Step.qr);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout() {
    _sessionState.logout();
    _phoneController.clear();
    // Oturum kapanınca AuthGate tam ekran LoginPage'e döner; sheet'i kapat.
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (_step) {
                _Step.phone => _phoneStep(),
                _Step.otp => _otpStep(),
                _Step.qr => _qrStep(),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Adım 1: Telefon ────────────────────────────────────────────────────
  Widget _phoneStep() {
    return Column(
      key: const ValueKey(_Step.phone),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetHeader(
          icon: Icons.qr_code_2_rounded,
          title: 'Personel Girişi',
          subtitle:
              'Telefon numaranıza gönderilecek tek kullanımlık kod ile giriş '
              'yapın ve yemekhane QR kodunuzu görüntüleyin.',
        ),
        AppSpacing.gapV24,
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            labelText: 'Telefon Numarası',
            hintText: '5XX XXX XX XX',
            prefixText: '+90  ',
            prefixStyle: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.red, width: 1.5),
            ),
          ),
        ),
        if (_error != null) _ErrorText(_error!),
        AppSpacing.gapV16,
        _PrimaryButton(
          label: 'Kod Gönder',
          loading: _loading,
          onPressed: _phone.length >= 10 ? _sendOtp : null,
        ),
      ],
    );
  }

  // ── Adım 2: OTP ────────────────────────────────────────────────────────
  Widget _otpStep() {
    return Column(
      key: const ValueKey(_Step.otp),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(
          icon: Icons.sms_rounded,
          title: 'Doğrulama Kodu',
          subtitle:
              '+90 $_phone numarasına gönderilen 6 haneli kodu girin.',
        ),
        AppSpacing.gapV24,
        OtpInput(
          hasError: _error != null,
          onChanged: (v) => setState(() {
            _code = v;
            _error = null;
          }),
          onCompleted: (v) {
            _code = v;
            _verify();
          },
        ),
        if (_error != null) _ErrorText(_error!),
        AppSpacing.gapV16,
        _PrimaryButton(
          label: 'Doğrula',
          loading: _loading,
          onPressed: _code.length == 6 ? _verify : null,
        ),
        AppSpacing.gapV8,
        TextButton(
          onPressed: _loading
              ? null
              : () => setState(() {
                  _step = _Step.phone;
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

  // ── Adım 3: QR ─────────────────────────────────────────────────────────
  Widget _qrStep() {
    final session = _sessionState.current;
    if (session == null) return _phoneStep();
    return Column(
      key: const ValueKey(_Step.qr),
      mainAxisSize: MainAxisSize.min,
      children: [
        StaffQrView(session: session),
        AppSpacing.gapV24,
        _PrimaryButton(
          label: 'Kapat',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        AppSpacing.gapV8,
        TextButton(
          onPressed: _logout,
          child: const Text(
            'Çıkış Yap',
            style: TextStyle(color: AppColors.red),
          ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            gradient: AppColors.redGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.white, size: 30),
        ),
        AppSpacing.gapV12,
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

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

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
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
