import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:flutter/material.dart';

class CountryCodeOption {
  final String code;
  final String iso;
  final String name;
  final String flag;

  const CountryCodeOption(this.code, this.iso, this.name, this.flag);
}

const List<CountryCodeOption> kCountryCodes = [
  CountryCodeOption('+91', 'IN', 'India', '🇮🇳'),
  CountryCodeOption('+1', 'US', 'United States', '🇺🇸'),
  CountryCodeOption('+44', 'GB', 'United Kingdom', '🇬🇧'),
  CountryCodeOption('+971', 'AE', 'UAE', '🇦🇪'),
  CountryCodeOption('+966', 'SA', 'Saudi Arabia', '🇸🇦'),
  CountryCodeOption('+974', 'QA', 'Qatar', '🇶🇦'),
  CountryCodeOption('+968', 'OM', 'Oman', '🇴🇲'),
  CountryCodeOption('+965', 'KW', 'Kuwait', '🇰🇼'),
  CountryCodeOption('+973', 'BH', 'Bahrain', '🇧🇭'),
  CountryCodeOption('+61', 'AU', 'Australia', '🇦🇺'),
  CountryCodeOption('+65', 'SG', 'Singapore', '🇸🇬'),
];

/// Reusable trigger + bottom sheet for picking a country code.
/// Used on both Login and Signup so the UI stays consistent.
class CountryCodeField extends StatelessWidget {
  final String selectedCode;
  final bool isValid;
  final ValueChanged<String> onChanged;

  const CountryCodeField({
    super.key,
    required this.selectedCode,
    required this.onChanged,
    this.isValid = true,
  });

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Select Country Code',
                    style: AppTextStyles.fieldLabel(context).copyWith(
                      fontSize: Responsive.font(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: kCountryCodes.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.inputBorder),
                    itemBuilder: (context, index) {
                      final c = kCountryCodes[index];
                      final isSelected = selectedCode == c.code;
                      return ListTile(
                        leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                        title: Text(
                          c.name,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: Responsive.font(context, 15),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        trailing: Text(
                          c.code,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.font(context, 15),
                          ),
                        ),
                        onTap: () {
                          onChanged(c.code);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: Responsive.space(context, 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPicker(context),
      child: Container(
        height: 52, // must match the adjacent phone field's height — verify
        padding: EdgeInsets.symmetric(horizontal: Responsive.space(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isValid ? AppColors.inputBorder : Colors.red,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCode,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: Responsive.font(context, 15),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: Responsive.space(context, 4)),
            Icon(Icons.arrow_drop_down, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }
}
/// A single merged field: country code trigger | divider | phone TextField.
/// Renders as one input box, with the country code where a phone icon
/// would normally sit — not two separate boxes.
class MergedPhoneField extends StatelessWidget {
  final String selectedCode;
  final TextEditingController phoneController;
  final bool isValid;
  final String errorText;
  final ValueChanged<String> onCodeChanged;
  final ValueChanged<String> onPhoneChanged;

  const MergedPhoneField({
    super.key,
    required this.selectedCode,
    required this.phoneController,
    required this.onCodeChanged,
    required this.onPhoneChanged,
    this.isValid = true,
    this.errorText = 'Enter a valid phone number',
  });

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Select Country Code',
                    style: AppTextStyles.fieldLabel(context).copyWith(
                      fontSize: Responsive.font(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: kCountryCodes.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.inputBorder),
                    itemBuilder: (context, index) {
                      final c = kCountryCodes[index];
                      final isSelected = selectedCode == c.code;
                      return ListTile(
                        leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                        title: Text(
                          c.name,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: Responsive.font(context, 15),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        trailing: Text(
                          c.code,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.font(context, 15),
                          ),
                        ),
                        onTap: () {
                          onCodeChanged(c.code);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: Responsive.space(context, 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isValid ? AppColors.inputBorder : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              SizedBox(width: Responsive.space(context, 12)),

              // Country code trigger — sits where a leading icon would go
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openPicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedCode,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: Responsive.font(context, 15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: Responsive.space(context, 2)),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textDark,
                      size: 20,
                    ),
                  ],
                ),
              ),

              SizedBox(width: Responsive.space(context, 10)),

              Container(
                width: 1,
                height: 28,
                color: AppColors.inputBorder,
              ),

              SizedBox(width: Responsive.space(context, 10)),

              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: onPhoneChanged,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: Responsive.font(context, 15),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    hintStyle: TextStyle(
                      color: AppColors.textDark.withOpacity(0.5),
                      fontSize: Responsive.font(context, 15),
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              SizedBox(width: Responsive.space(context, 12)),
            ],
          ),
        ),
        if (!isValid) ...[
          SizedBox(height: Responsive.space(context, 6)),
          Text(
            errorText,
            style: TextStyle(
              color: Colors.red,
              fontSize: Responsive.font(context, 12),
            ),
          ),
        ],
      ],
    );
  }
}