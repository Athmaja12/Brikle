import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:brikle/ProfilePage/Model/address_model.dart';
import 'package:brikle/ProfilePage/View/couponscreen.dart';
import 'package:brikle/ProfilePage/View/orderListScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController _ctrl = Get.put(ProfileController());
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Obx(() {
          if (_ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: _ctrl.refreshAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        _buildDeliveryAddress(context),
                        SizedBox(height: Responsive.space(context, 20)),
                        _buildAppSettings(context),
                        SizedBox(height: Responsive.space(context, 16)),
                        _buildDeleteAccount(context),
                        SizedBox(height: Responsive.space(context, 20)),
                      ],
                    ),
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
        // ── Tappable avatar → opens "My Details" dialog ─────────────────────
        GestureDetector(
          onTap: () => _showProfileDetailsDialog(context),
          child: Container(
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
        ),
        SizedBox(width: Responsive.space(context, 12)),
        Expanded(
          child: GestureDetector(
            onTap: () => _showProfileDetailsDialog(context),
            behavior: HitTestBehavior.opaque,
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
        ),
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

  // ── "My Details" dialog ──────────────────────────────────────────────────
  void _showProfileDetailsDialog(BuildContext context) {
    final p = _ctrl.profile.value;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name + verified badge
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(p.fullName),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.fullName.isNotEmpty ? p.fullName : '—',
                                  style: GoogleFonts.manrope(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inputText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.primaryGreen,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            p.isVerified ? 'Verified account' : 'Not verified',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: p.isVerified
                                  ? AppColors.primaryGreen
                                  : AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textGray,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 8),

                _detailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: p.phoneNumber.isNotEmpty ? p.phoneNumber : '—',
                ),
                _detailRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: p.email?.isNotEmpty == true ? p.email! : '—',
                ),
                _detailRow(
                  icon: Icons.badge_outlined,
                  label: 'Account Type',
                  value: p.customerTypeLabel,
                ),
                if (p.customerType == 'contractor' &&
                    (p.gstNumber?.isNotEmpty ?? false))
                  _detailRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'GST Number',
                    value: p.gstNumber!,
                  ),
                _detailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: p.address.isNotEmpty ? p.address : '—',
                ),
                _detailRow(
                  icon: Icons.pin_drop_outlined,
                  label: 'Pincode',
                  value: p.pincode.isNotEmpty ? p.pincode : '—',
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _showEditProfileSheet();
                    },
                    child: Text(
                      'Edit Profile',
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
        );
      },
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textGray),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.inputText,
              ),
            ),
          ),
        ],
      ),
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
          onTap: () => Get.to(() => const OrderListScreen()),
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
        SizedBox(width: Responsive.space(context, 10)),
        _actionCard(
          context,
          icon: Icons.local_offer_outlined,
          label: 'Coupons',
          iconColor: AppColors.primaryGreen,
          onTap: () => Get.to(() => CouponScreen()),
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

  // ── Delivery Address ─────────────────────────────────────────────────────
  // Address BOOK (multiple saved addresses) via /api/addresses/.
  // Fully separate from the single profile address/pincode fields edited
  // in the "Edit Profile" sheet (PATCH /api/customer-profile/).
  Widget _buildDeliveryAddress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Delivery Address',
                style: GoogleFonts.manrope(
                  fontSize: Responsive.font(context, 15),
                  fontWeight: FontWeight.w600,
                  color: AppColors.inputText,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showManageAddressesDialog(context),
              child: Text(
                'Manage',
                style: GoogleFonts.manrope(
                  fontSize: Responsive.font(context, 13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.space(context, 10)),
        Obx(() {
          if (_ctrl.isAddressesLoading.value && _ctrl.addresses.isEmpty) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(Responsive.space(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, 12),
                ),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            );
          }

          final primary = _ctrl.primaryAddress;

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.space(context, 16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, 12),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primaryGreen,
                  size: Responsive.space(context, 20),
                ),
                SizedBox(width: Responsive.space(context, 10)),
                Expanded(
                  child: primary != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primary.fullAddress,
                              style: GoogleFonts.manrope(
                                fontSize: Responsive.font(context, 13),
                                fontWeight: FontWeight.w400,
                                color: AppColors.inputText,
                                height: 1.5,
                              ),
                            ),
                            if (_ctrl.addresses.length > 1) ...[
                              const SizedBox(height: 4),
                              Text(
                                '+ ${_ctrl.addresses.length - 1} more saved address${_ctrl.addresses.length > 2 ? 'es' : ''}',
                                style: GoogleFonts.manrope(
                                  fontSize: Responsive.font(context, 12),
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          'No delivery address saved yet.',
                          style: GoogleFonts.manrope(
                            fontSize: Responsive.font(context, 13),
                            color: AppColors.textGray,
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () => _showManageAddressesDialog(context),
                  child: Icon(
                    Icons.edit_outlined,
                    size: Responsive.space(context, 18),
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Manage Addresses Dialog (list + add/edit/delete/set primary) ──────────
  void _showManageAddressesDialog(BuildContext context) {
    _ctrl.fetchAddresses();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Delivery Addresses',
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inputText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textGray,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Obx(() {
                    if (_ctrl.isAddressesLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      );
                    }

                    if (_ctrl.addresses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No saved addresses yet.',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: _ctrl.addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final addr = _ctrl.addresses[index];
                        return _addressTile(addr);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () => _showAddEditAddressDialog(context),
                    icon: const Icon(Icons.add, color: AppColors.primaryGreen),
                    label: Text(
                      'Add New Address',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
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

  Widget _addressTile(DeliveryAddressModel addr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: addr.isPrimary
            ? AppColors.primaryGreen.withOpacity(0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: addr.isPrimary
              ? AppColors.primaryGreen.withOpacity(0.4)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: addr.isPrimary ? AppColors.primaryGreen : AppColors.textGray,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (addr.isPrimary)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'PRIMARY',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                Text(
                  addr.addressLine,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inputText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pincode: ${addr.pincode}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
            onSelected: (value) {
              if (value == 'edit') {
                _showAddEditAddressDialog(Get.context!, existing: addr);
              } else if (value == 'primary') {
                _ctrl.setPrimaryAddress(addr.id);
              } else if (value == 'delete') {
                _ctrl.deleteAddress(addr.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (!addr.isPrimary)
                const PopupMenuItem(
                  value: 'primary',
                  child: Text('Set as Primary'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Add / Edit Address Dialog ──────────────────────────────────────────────
  void _showAddEditAddressDialog(
    BuildContext context, {
    DeliveryAddressModel? existing,
  }) {
    final isEdit = existing != null;
    final addressCtrl = TextEditingController(
      text: existing?.addressLine ?? '',
    );
    final pincodeCtrl = TextEditingController(text: existing?.pincode ?? '');
    bool isPrimary = existing?.isPrimary ?? _ctrl.addresses.isEmpty;
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (dialogCtx, setDialog) => Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Address' : 'Add New Address',
                            style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inputText,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close, size: 20),
                          color: AppColors.textGray,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _dialogLabeledField(
                      'Address',
                      addressCtrl,
                      maxLines: 2,
                      hint: 'House/Flat No, Street, Area',
                    ),
                    const SizedBox(height: 14),
                    _dialogLabeledField(
                      'Pincode',
                      pincodeCtrl,
                      keyboard: TextInputType.number,
                      hint: 'Enter 6-digit pincode',
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => setDialog(() => isPrimary = !isPrimary),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Checkbox(
                            value: isPrimary,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (v) =>
                                setDialog(() => isPrimary = v ?? false),
                          ),
                          Text(
                            'Set as primary delivery address',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inputText,
                            ),
                          ),
                        ],
                      ),
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
                        onPressed: isSaving
                            ? null
                            : () async {
                                final line = addressCtrl.text.trim();
                                final pincode = pincodeCtrl.text.trim();

                                if (line.isEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    'Please enter the address',
                                  );
                                  return;
                                }
                                if (pincode.length != 6) {
                                  Get.snackbar(
                                    'Error',
                                    'Please enter a valid 6-digit pincode',
                                  );
                                  return;
                                }

                                setDialog(() => isSaving = true);

                                final success = isEdit
                                    ? await _ctrl.updateAddress(
                                        addressId: existing.id,
                                        addressLine: line,
                                        pincode: pincode,
                                        isPrimary: isPrimary,
                                      )
                                    : await _ctrl.addAddress(
                                        addressLine: line,
                                        pincode: pincode,
                                        isPrimary: isPrimary,
                                      );

                                setDialog(() => isSaving = false);
                                if (success) Get.back();
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit ? 'Save Changes' : 'Add Address',
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
        ),
      ),
      barrierColor: Colors.black54,
    );
  }

  Widget _dialogLabeledField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: GoogleFonts.manrope(fontSize: 14, color: AppColors.inputText),
          decoration: InputDecoration(
            hintText: hint ?? '',
            hintStyle: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textGray,
            ),
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
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
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

  // ── Edit Profile Sheet ──────────────────────────────────────────────────────
  // Covers every field the backend's PATCH /api/customer-profile/ accepts:
  // full_name, email, address, pincode, customer_type, gst_number.
  void _showEditProfileSheet() {
    final p = _ctrl.profile.value;
    final nameCtrl = TextEditingController(text: p.fullName);
    final emailCtrl = TextEditingController(text: p.email ?? '');
    final addrCtrl = TextEditingController(text: p.address);
    final pincodeCtrl = TextEditingController(text: p.pincode);
    final gstCtrl = TextEditingController(text: p.gstNumber ?? '');
    String customerType = p.customerType ?? 'home_owner';
    bool isLoading = false;

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Profile',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inputText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _sheetLabeledField('Full Name', nameCtrl),
                const SizedBox(height: 14),
                _sheetLabeledField(
                  'Email',
                  emailCtrl,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _sheetLabeledField('Address', addrCtrl, maxLines: 2),
                const SizedBox(height: 14),
                _sheetLabeledField(
                  'Pincode',
                  pincodeCtrl,
                  keyboard: TextInputType.number,
                  hint: 'Enter 6-digit pincode',
                ),

                const SizedBox(height: 16),
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
                        label: 'Home Owner',
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

                if (customerType == 'contractor') ...[
                  const SizedBox(height: 14),
                  _sheetLabeledField(
                    'GST Number',
                    gstCtrl,
                    hint: 'Enter GST number (Optional)',
                  ),
                ],

                const SizedBox(height: 24),
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
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (pincodeCtrl.text.trim().isNotEmpty &&
                                pincodeCtrl.text.trim().length != 6) {
                              Get.snackbar(
                                'Error',
                                'Please enter a valid 6-digit pincode',
                              );
                              return;
                            }
                            if (customerType == 'contractor' &&
                                gstCtrl.text.trim().isNotEmpty &&
                                !_ctrl.isGstValid(gstCtrl.text.trim())) {
                              Get.snackbar(
                                'Invalid GST',
                                'Enter a valid GST number.',
                              );
                              return;
                            }

                            setSheet(() => isLoading = true);

                            final success = await _ctrl.updateProfile(
                              fullName: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              address: addrCtrl.text.trim(),
                              pincode: pincodeCtrl.text.trim(),
                              customerType: customerType,
                              gstNumber:
                                  customerType == 'contractor' &&
                                      gstCtrl.text.trim().isNotEmpty
                                  ? gstCtrl.text.trim().toUpperCase()
                                  : null,
                            );

                            setSheet(() => isLoading = false);
                            if (success) Get.back();
                          },
                    child: isLoading
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared Helpers ──────────────────────────────────────────────────────────

  Widget _sheetLabeledField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: GoogleFonts.manrope(fontSize: 14, color: AppColors.inputText),
          decoration: InputDecoration(
            hintText: hint ?? '',
            hintStyle: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textGray,
            ),
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
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

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
