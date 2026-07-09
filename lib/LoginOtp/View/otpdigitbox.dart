import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// OTP digit box — styled to match CustomPhoneField (Login screen):
/// height 48, radius 12, border #E2E2E2, white fill,
/// shadow 0px 4px 12px rgba(0,0,0,0.04).
class OtpDigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isValid;
  final ValueChanged<String> onChanged;

  const OtpDigitBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.isValid = true,
  });

  @override
  State<OtpDigitBox> createState() => _OtpDigitBoxState();
}

class _OtpDigitBoxState extends State<OtpDigitBox> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.focusNode.addListener(_onFocusChanged);
    _hasFocus = widget.focusNode.hasFocus;
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _hasFocus = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  Color get _borderColor {
    if (!widget.isValid) return AppColors.errorRed;
    if (_hasFocus) return AppColors.primaryGreen;
    return AppColors.inputBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Responsive.space(context, 52),
      height: Responsive.height(context, 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _borderColor,
          width: _hasFocus || !widget.isValid ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          enableInteractiveSelection: false,
          style: AppTextStyles.inputText(context).copyWith(
            fontSize: Responsive.font(context, 18),
            fontWeight: FontWeight.w600,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.isNotEmpty || widget.controller.text.isEmpty) {
              widget.onChanged(value);
            }
          },
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isCollapsed: true,
          ),
        ),
      ),
    );
  }
}
