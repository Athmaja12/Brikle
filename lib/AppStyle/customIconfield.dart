import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:flutter/material.dart';

class CustomIconField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool isValid;
  final String errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;

  const CustomIconField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hintText,
    this.isValid = true,
    this.errorText = '',
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: Responsive.height(context, 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isValid ? AppColors.inputBorder : AppColors.errorRed,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: Responsive.space(context, 16)),
              Icon(
                icon,
                size: Responsive.space(context, 20),
                color: AppColors.textGray,
              ),
              SizedBox(width: Responsive.space(context, 8)),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  style: AppTextStyles.inputText(context),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: AppTextStyles.inputText(context).copyWith(
                      color: AppColors.textGray,
                      fontSize:
                          (AppTextStyles.inputText(context).fontSize ?? 10) - 6,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(width: Responsive.space(context, 12)),
            ],
          ),
        ),
        if (!isValid && errorText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: 6,
              left: Responsive.space(context, 4),
            ),
            child: Text(errorText, style: AppTextStyles.errorText(context)),
          ),
      ],
    );
  }
}
