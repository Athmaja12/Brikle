import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:brikle/ProfilePage/Model/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Controller is already registered by the binding / parent route.
  // Use Get.find so we never double-register it.
  late final ProfileController _ctrl = Get.put(ProfileController());

  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Obx(() {
          // Full-screen loader on first fetch
          if (_ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, 16),
                    vertical: Responsive.space(context, 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      SizedBox(height: Responsive.space(context, 20)),
                      _buildQuickActions(context),
                      SizedBox(height: Responsive.space(context, 20)),
                      _buildSavedAddresses(context),
                      SizedBox(height: Responsive.space(context, 20)),
                      _buildAppSettings(context),
                      SizedBox(height: Responsive.space(context, 16)),
                      _buildDeleteAccount(context),
                      SizedBox(height: Responsive.space(context, 20)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar circle with initials
        Container(
          width: Responsive.space(context, 52),
          height: Responsive.space(context, 52),
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(_ctrl.fullName),
            style: GoogleFonts.manrope(
              fontSize: Responsive.font(context, 18),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: Responsive.space(context, 12)),

        // Name + phone
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _ctrl.fullName.isNotEmpty ? _ctrl.fullName : '—',
                      style: GoogleFonts.manrope(
                        fontSize: Responsive.font(context, 20),
                        fontWeight: FontWeight.w700,
                        color: AppColors.inputText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_ctrl.isVerified) ...[
                    SizedBox(width: Responsive.space(context, 6)),
                    Icon(
                      Icons.verified_rounded,
                      color: AppColors.primaryGreen,
                      size: Responsive.space(context, 16),
                    ),
                  ],
                ],
              ),
              SizedBox(height: Responsive.space(context, 4)),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: Responsive.space(context, 14),
                    color: AppColors.textGray,
                  ),
                  SizedBox(width: Responsive.space(context, 6)),
                  Text(
                    _ctrl.phoneNumber.isNotEmpty ? _ctrl.phoneNumber : '—',
                    style: GoogleFonts.manrope(
                      fontSize: Responsive.font(context, 13),
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
              if (_ctrl.email.isNotEmpty) ...[
                SizedBox(height: Responsive.space(context, 2)),
                Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: Responsive.space(context, 14),
                      color: AppColors.textGray,
                    ),
                    SizedBox(width: Responsive.space(context, 6)),
                    Flexible(
                      child: Text(
                        _ctrl.email,
                        style: GoogleFonts.manrope(
                          fontSize: Responsive.font(context, 13),
                          fontWeight: FontWeight.w400,
                          color: AppColors.textGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Notification bell
        GestureDetector(
          onTap: () => setState(() => _notificationsOn = !_notificationsOn),
          child: Container(
            width: Responsive.space(context, 44),
            height: Responsive.space(context, 44),
            decoration: BoxDecoration(
              color: _notificationsOn
                  ? AppColors.primaryGreen
                  : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _notificationsOn
                  ? Icons.notifications_rounded
                  : Icons.notifications_off_outlined,
              color: _notificationsOn ? Colors.white : AppColors.textGray,
              size: Responsive.space(context, 22),
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ───────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _actionCard(
          context,
          icon: Icons.inventory_2_outlined,
          label: 'My Orders',
          onTap: () => Get.toNamed('/orders'),
        ),
        SizedBox(width: Responsive.space(context, 10)),
        _actionCard(
          context,
          icon: Icons.favorite,
          label: 'Wishlist',
          iconColor: AppColors.primaryGreen,
          onTap: () => Get.toNamed('/wishlist'),
        ),
        SizedBox(width: Responsive.space(context, 10)),
        _actionCard(
          context,
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          onTap: _showEditProfileSheet,
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color iconColor = AppColors.inputText,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.space(context, 16),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: Responsive.space(context, 24)),
              SizedBox(height: Responsive.space(context, 8)),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: Responsive.font(context, 12),
                  fontWeight: FontWeight.w500,
                  color: AppColors.inputText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Saved Addresses ─────────────────────────────────────────────────────────
  Widget _buildSavedAddresses(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Addresses',
          style: GoogleFonts.manrope(
            fontSize: Responsive.font(context, 15),
            fontWeight: FontWeight.w600,
            color: AppColors.inputText,
          ),
        ),
        SizedBox(height: Responsive.space(context, 10)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Obx(() {
            final addrs = _ctrl.addresses;
            return Column(
              children: [
                if (addrs.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(Responsive.space(context, 16)),
                    child: Text(
                      'No saved addresses yet.',
                      style: GoogleFonts.manrope(
                        fontSize: Responsive.font(context, 13),
                        color: AppColors.textGray,
                      ),
                    ),
                  )
                else
                  ...List.generate(addrs.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      return const Divider(height: 1, color: Color(0xFFE5E7EB));
                    }
                    return _addressItem(context, address: addrs[i ~/ 2]);
                  }),

                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Add New Location button
                Padding(
                  padding: EdgeInsets.all(Responsive.space(context, 14)),
                  child: GestureDetector(
                    onTap: _showAddAddressSheet,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.space(context, 10),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryGreen),
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, 24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Add New Location ',
                            style: GoogleFonts.manrope(
                              fontSize: Responsive.font(context, 13),
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          Icon(
                            Icons.add,
                            color: AppColors.primaryGreen,
                            size: Responsive.space(context, 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _addressItem(BuildContext context, {required AddressModel address}) {
    return Padding(
      padding: EdgeInsets.all(Responsive.space(context, 14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.isPrimary ? 'Home' : 'Address',
                      style: GoogleFonts.manrope(
                        fontSize: Responsive.font(context, 14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.inputText,
                      ),
                    ),
                    if (address.isPrimary) ...[
                      SizedBox(width: Responsive.space(context, 8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(context, 10),
                          vertical: Responsive.space(context, 3),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EE),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, 20),
                          ),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.manrope(
                            fontSize: Responsive.font(context, 11),
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Responsive.space(context, 4)),
                Text(
                  address.fullAddress,
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 12),
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGray,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          GestureDetector(
            onTap: () => _showEditAddressSheet(address),
            child: Icon(
              Icons.edit_outlined,
              size: Responsive.space(context, 18),
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  // ── App Settings ────────────────────────────────────────────────────────────
  Widget _buildAppSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Settings',
          style: GoogleFonts.manrope(
            fontSize: Responsive.font(context, 15),
            fontWeight: FontWeight.w600,
            color: AppColors.inputText,
          ),
        ),
        SizedBox(height: Responsive.space(context, 10)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _settingsRow(
                context,
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                trailing: GestureDetector(
                  onTap: () =>
                      setState(() => _notificationsOn = !_notificationsOn),
                  child: Text(
                    _notificationsOn ? 'On' : 'Off',
                    style: GoogleFonts.manrope(
                      fontSize: Responsive.font(context, 13),
                      fontWeight: FontWeight.w500,
                      color: _notificationsOn
                          ? AppColors.primaryGreen
                          : AppColors.textGray,
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: Responsive.space(context, 50),
                color: const Color(0xFFE5E7EB),
              ),
              _settingsRow(
                context,
                icon: Icons.translate_outlined,
                label: 'Language',
                trailing: Text(
                  'English',
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 13),
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: Responsive.space(context, 50),
                color: const Color(0xFFE5E7EB),
              ),
              Obx(
                () => _settingsRow(
                  context,
                  icon: Icons.logout,
                  label: 'Logout',
                  trailing: _ctrl.isLoading.value
                      ? SizedBox(
                          width: Responsive.space(context, 16),
                          height: Responsive.space(context, 16),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        )
                      : GestureDetector(
                          onTap: _ctrl.logout,
                          child: Text(
                            'Logout',
                            style: GoogleFonts.manrope(
                              fontSize: Responsive.font(context, 13),
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: Responsive.space(context, 14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: Responsive.space(context, 20),
            color: AppColors.inputText,
          ),
          SizedBox(width: Responsive.space(context, 14)),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: Responsive.font(context, 14),
                fontWeight: FontWeight.w400,
                color: AppColors.inputText,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  // ── Delete Account ──────────────────────────────────────────────────────────
  Widget _buildDeleteAccount(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: _ctrl.isDeleting.value ? null : _ctrl.deleteAccount,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, 16),
            vertical: Responsive.space(context, 16),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.space(context, 12)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: _ctrl.isDeleting.value
              ? const SizedBox(
                  height: 20,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.errorRed,
                    ),
                  ),
                )
              : Text(
                  'Delete Account Forever',
                  style: GoogleFonts.manrope(
                    fontSize: Responsive.font(context, 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.errorRed,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Bottom Sheets ───────────────────────────────────────────────────────────

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _ctrl.fullName);
    final emailCtrl = TextEditingController(text: _ctrl.email);
    final addrCtrl = TextEditingController(text: _ctrl.address);

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.inputText,
              ),
            ),
            const SizedBox(height: 20),
            _sheetField('Full Name', nameCtrl),
            const SizedBox(height: 14),
            _sheetField(
              'Email',
              emailCtrl,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _sheetField('Address', addrCtrl, maxLines: 2),
            const SizedBox(height: 24),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _ctrl.isUpdating.value
                      ? null
                      : () async {
                          await _ctrl.updateProfile(
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            address: addrCtrl.text.trim(),
                          );
                          Get.back();
                        },
                  child: _ctrl.isUpdating.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressSheet() {
    final street1Ctrl = TextEditingController();
    final street2Ctrl = TextEditingController();
    final pincodeCtrl = TextEditingController();
    final gstCtrl = TextEditingController();
    bool isPrimary = false;
    String customerType = 'home_owner'; // assumption — see note below

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Location',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inputText,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Account Type',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AccountTypeChip(
                        label: 'Individual',
                        selected: customerType == 'home_owner',
                        onTap: () =>
                            setSheet(() => customerType = 'home_owner'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AccountTypeChip(
                        label: 'Contractor',
                        selected: customerType == 'contractor',
                        onTap: () =>
                            setSheet(() => customerType = 'contractor'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _sheetField('Street Address 1', street1Ctrl),
                const SizedBox(height: 14),
                _sheetField('Street Address 2', street2Ctrl),
                const SizedBox(height: 14),
                _sheetField(
                  'Pincode',
                  pincodeCtrl,
                  keyboard: TextInputType.number,
                ),

                if (customerType == 'contractor') ...[
                  const SizedBox(height: 14),
                  _sheetField('GST Number', gstCtrl),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isPrimary,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (v) => setSheet(() => isPrimary = v ?? false),
                    ),
                    Text(
                      'Set as default address',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.inputText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () async {
                      if (street1Ctrl.text.trim().isEmpty ||
                          pincodeCtrl.text.trim().isEmpty) {
                        return;
                      }
                      if (customerType == 'contractor' &&
                          !_ctrl.isGstValid(gstCtrl.text)) {
                        Get.snackbar(
                          'Invalid GST',
                          'Enter a valid GST number.',
                        );
                        return;
                      }
                      await _ctrl.addAddress(
                        streetAddress1: street1Ctrl.text.trim(),
                        streetAddress2: street2Ctrl.text.trim(),
                        pincode: pincodeCtrl.text.trim(),
                        isPrimary: isPrimary,
                        customerType: customerType,
                        gstNumber: customerType == 'contractor'
                            ? gstCtrl.text.trim()
                            : null,
                      );
                      Get.back();
                    },
                    child: Text(
                      'Add Address',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAddressSheet(AddressModel address) {
    final street1Ctrl = TextEditingController(text: address.streetAddress1);
    final street2Ctrl = TextEditingController(text: address.streetAddress2);
    final pincodeCtrl = TextEditingController(text: address.pincode);
    final gstCtrl = TextEditingController(text: address.gstNumber ?? '');
    bool isPrimary = address.isPrimary;
    String customerType = address.customerType ?? 'home_owner';

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Address',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inputText,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Account Type',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _AccountTypeChip(
                        label: 'Individual',
                        selected: customerType == 'home_owner',
                        onTap: () =>
                            setSheet(() => customerType = 'home_owner'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AccountTypeChip(
                        label: 'Contractor',
                        selected: customerType == 'contractor',
                        onTap: () =>
                            setSheet(() => customerType = 'contractor'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _sheetField('Street Address 1', street1Ctrl),
                const SizedBox(height: 14),
                _sheetField('Street Address 2', street2Ctrl),
                const SizedBox(height: 14),
                _sheetField(
                  'Pincode',
                  pincodeCtrl,
                  keyboard: TextInputType.number,
                ),

                if (customerType == 'contractor') ...[
                  const SizedBox(height: 14),
                  _sheetField('GST Number', gstCtrl),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isPrimary,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (v) => setSheet(() => isPrimary = v ?? false),
                    ),
                    Text(
                      'Set as default address',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.inputText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () async {
                      if (street1Ctrl.text.trim().isEmpty ||
                          pincodeCtrl.text.trim().isEmpty) {
                        return;
                      }
                      if (customerType == 'contractor' &&
                          !_ctrl.isGstValid(gstCtrl.text)) {
                        Get.snackbar(
                          'Invalid GST',
                          'Enter a valid GST number.',
                        );
                        return;
                      }
                      await _ctrl.addAddress(
                        streetAddress1: street1Ctrl.text.trim(),
                        streetAddress2: street2Ctrl.text.trim(),
                        pincode: pincodeCtrl.text.trim(),
                        isPrimary: isPrimary,
                        customerType: customerType,
                        gstNumber: customerType == 'contractor'
                            ? gstCtrl.text.trim().toUpperCase()
                            : null,
                      );
                      Get.back();
                    },
                    child: Text(
                      'Save Address',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  Widget _sheetField(
    String hint,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.manrope(fontSize: 14, color: AppColors.inputText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(fontSize: 14, color: AppColors.textGray),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen),
        ),
      ),
    );
  }

  /// Returns up to 2 uppercase initials from a full name.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _AccountTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AccountTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: Responsive.height(context, 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : const Color(0xFFE5E7EB),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: Responsive.font(context, 13),
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.inputText,
          ),
        ),
      ),
    );
  }
}
