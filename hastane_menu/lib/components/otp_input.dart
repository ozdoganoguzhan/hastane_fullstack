import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hastane_menu/core/constants/app_colors.dart';

/// 6 (veya N) haneli kod giriş alanı — tek kutular halinde gösterilir,
/// arkada gizli bir TextField klavyeyi yönetir.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.autofocus = true,
    this.hasError = false,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool hasError;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted(value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _focusNode.requestFocus,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < widget.length; i++) _box(i),
            ],
          ),
          // Gizli ama odaklanabilir gerçek giriş alanı.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                showCursor: false,
                onChanged: _handleChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(int index) {
    final text = _controller.text;
    final filled = index < text.length;
    final isActive = index == text.length && _focusNode.hasFocus;
    final Color borderColor = widget.hasError
        ? AppColors.error
        : isActive
        ? AppColors.red
        : AppColors.border;

    return Container(
      width: 46,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isActive || widget.hasError ? 1.8 : 1.2,
        ),
      ),
      child: Text(
        filled ? text[index] : '',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }
}
