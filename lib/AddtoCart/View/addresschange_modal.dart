// lib/AddtoCart/View/addresschange_modal.dart

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/AddtoCart/View/ordersuccess_screen.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressChangeModal extends StatefulWidget {
  final CartController controller;

  const AddressChangeModal({super.key, required this.controller});

  @override
  State<AddressChangeModal> createState() => _AddressChangeModalState();
}

class _AddressChangeModalState extends State<AddressChangeModal> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isPincodeValid = false;
  bool _isCheckingPincode = false;
  bool _isLoading = false;
  List<VehicleModel> _vehicles = [];
  VehicleModel? _selectedVehicle;
  String? _pincodeStatusMessage;
  DateTime? _selectedDeliveryDate;
  TimeOfDay? _selectedDeliveryTime;

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
    _loadVehicles();
    _selectedDeliveryDate = DateTime.now().add(const Duration(days: 1));
    _selectedDeliveryTime = const TimeOfDay(hour: 10, minute: 0);
  }

  void _loadCurrentAddress() async {
    try {
      final profile = await ApiService.getProfile();
      final address = AddressModel.fromJson(profile);
      _addressController.text = address.address;
      _pincodeController.text = address.pincode;
      _nameController.text = address.fullName ?? '';
      _phoneController.text = address.phoneNumber ?? '';
      _emailController.text = address.email ?? '';
    } catch (e) {
      debugPrint('Error loading address: $e');
    }
  }

  void _loadVehicles() async {
    try {
      final vehicles = await ApiService.getAvailableVehicles();
      setState(() {
        _vehicles = vehicles;
        if (vehicles.isNotEmpty) {
          _selectedVehicle = vehicles.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    }
  }

  Future<void> _checkPincode() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.isEmpty || pincode.length != 6) {
      setState(() {
        _pincodeStatusMessage = 'Please enter a valid 6-digit pincode';
        _isPincodeValid = false;
      });
      return;
    }

    setState(() {
      _isCheckingPincode = true;
      _pincodeStatusMessage = null;
    });

    try {
      final response = await ApiService.checkPincode(pincode);
      final result = PincodeCheckResponse.fromJson(response);

      setState(() {
        _isPincodeValid = result.isServiceable;
        _pincodeStatusMessage = result.message;
        _isCheckingPincode = false;
      });

      if (result.isServiceable) {
        _showDistanceAlert();
      }
    } catch (e) {
      setState(() {
        _pincodeStatusMessage = 'Error checking pincode. Please try again.';
        _isPincodeValid = false;
        _isCheckingPincode = false;
      });
    }
  }

  void _showDistanceAlert() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Delivery Distance Notice",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "The delivery charge depends on the distance between our store and your delivery location.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF8E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffF4D28A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPoint(
                      "Delivery distance affects the shipping charge.",
                    ),

                    const SizedBox(height: 12),

                    _buildPoint(
                      "Longer distances may have additional delivery fees.",
                    ),

                    const SizedBox(height: 12),

                    _buildPoint(
                      "The final delivery charge will be shown before you place the order.",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: Get.back,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "I Understand",
                    style: TextStyle(
                      fontSize: 16,
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
      barrierDismissible: true,
    );
  }

  Widget _buildPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  Future<void> _selectDeliveryTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _selectedDeliveryTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedDeliveryTime = picked;
      });
    }
  }

  /// Formats TimeOfDay as "HH:MM:SS" (24-hour) for the API.
  String _formatTimeForApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  /// Formats TimeOfDay for display, e.g. "10:00 AM"
  String _formatTimeForDisplay(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  Future<void> _placeOrder() async {
    if (!_isPincodeValid) {
      Get.snackbar(
        'Invalid Pincode',
        'Please check your pincode first',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedDeliveryDate == null) {
      Get.snackbar(
        'Delivery Date',
        'Please select a delivery date',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedDeliveryTime == null) {
      Get.snackbar(
        'Delivery Time',
        'Please select a delivery time',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final address = AddressModel(
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        pincode: _pincodeController.text,
      );

      await widget.controller.updateAddress(address);

      if (_selectedVehicle != null) {
        widget.controller.selectedVehicle.value = _selectedVehicle;
      }

      final dateString = _selectedDeliveryDate!
          .toIso8601String()
          .split('T')
          .first;
      final timeString = _formatTimeForApi(_selectedDeliveryTime!);

      widget.controller.selectedDeliveryDate.value = dateString;
      widget.controller.selectedDeliveryTime.value = timeString;

      final checkoutResult = await widget.controller.processCheckout(
        pincode: _pincodeController.text,
        deliveryDate: dateString,
        deliveryTime: timeString,
        couponId: widget.controller.selectedCoupon.value?.id,
      );

      if (checkoutResult == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      if (!checkoutResult.deliveryAvailable) {
        if (!mounted) return;
        Get.dialog(
          AlertDialog(
            title: const Text('❌ Delivery Not Available'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We are currently unable to deliver to this location.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          checkoutResult.message,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please try a different pincode or contact our support team.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final proceed = await _showDeliveryChargeBreakdown(checkoutResult);
      if (!proceed) {
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.back(result: true);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Address Added',
          'Now select a payment method to complete your order',
          backgroundColor: AppColors.primaryGreen,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to update address: $e');
      setState(() => _isLoading = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _placeActualOrder(
    AddressModel address,
    String dateString,
    String timeString, // NEW
  ) async {
    Get.dialog(
      barrierDismissible: false,
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Placing your order...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final orderResult = await widget.controller.placeOrder(
        shippingAddress: address.address,
        pincode: address.pincode,
        deliveryDate: dateString,
        deliveryTime: timeString, // NEW
      );

      Get.back();

      if (orderResult != null) {
        Get.offAll(() => const OrderSuccessScreen());
      } else {
        Get.snackbar(
          'Order Failed',
          'Unable to place order. Please try again.',
          backgroundColor: AppColors.errorRed,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to place order: $e',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
    }
  }

  // FIX: was `void`, fired via Get.dialog() without awaiting — so
  // _placeOrder() below moved straight on to placing the order without
  // ever waiting for the user to tap "Proceed to Pay". Now returns a
  // Future<bool> that only resolves once the user picks an action.
  Future<bool> _showDeliveryChargeBreakdown(CheckoutResponse response) async {
    final config = response.deliveryConfig;

    final result = await Get.dialog<bool>(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Title
              const Text(
                "Delivery Charges",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 8),

              Text(
                response.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              /// Details Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xffF8F9FB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  children: [
                    _buildChargeRow(
                      "Scheduled Delivery",
                      "${response.scheduledDeliveryDate} • ${response.scheduledDeliveryTime}",
                    ),

                    const Divider(height: 26),

                    _buildChargeRow(
                      "Delivery Distance",
                      "${config.totalDistanceKm.toStringAsFixed(1)} km",
                    ),

                    const Divider(height: 26),

                    _buildChargeRow(
                      "Free Distance",
                      "${config.freeDistanceLimitKm} km",
                    ),

                    const Divider(height: 26),

                    _buildChargeRow(
                      "Additional Distance",
                      "${config.extraDistance.toStringAsFixed(1)} km",
                    ),

                    const Divider(height: 26),

                    _buildChargeRow(
                      "Rate",
                      "₹${config.chargePerExtraKm.toStringAsFixed(0)} / km",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Total Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Delivery Charge",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      "₹${response.paymentSummary.deliveryCharge.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Proceed to Payment",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  Widget _buildChargeRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primaryGreen : null,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textGray, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.space(context, 8)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          SizedBox(width: Responsive.space(context, 6)),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 5, bottom: 45),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Responsive.space(context, 20),
          Responsive.space(context, 12),
          Responsive.space(context, 20),
          Responsive.space(context, 20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: Responsive.space(context, 16)),
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Delivery Address',
                  style: AppTextStyles.welcomeBackTitle(
                    context,
                  ).copyWith(fontSize: 18),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, 20)),

            _sectionLabel(context, Icons.person_outline, 'CONTACT DETAILS'),
            TextField(
              controller: _nameController,
              style: AppTextStyles.inputText(context),
              decoration: _fieldDecoration(
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
            ),
            SizedBox(height: Responsive.space(context, 12)),
            TextField(
              controller: _phoneController,
              style: AppTextStyles.inputText(context),
              decoration: _fieldDecoration(
                label: 'Phone Number',
                icon: Icons.call_outlined,
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: Responsive.space(context, 12)),
            TextField(
              controller: _emailController,
              style: AppTextStyles.inputText(context),
              decoration: _fieldDecoration(
                label: 'Email (Optional)',
                icon: Icons.mail_outline,
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            SizedBox(height: Responsive.space(context, 24)),
            _sectionLabel(
              context,
              Icons.location_on_outlined,
              'DELIVERY LOCATION',
            ),
            TextField(
              controller: _addressController,
              style: AppTextStyles.inputText(context),
              decoration: _fieldDecoration(
                label: 'Delivery Address',
                icon: Icons.home_outlined,
              ),
              maxLines: 2,
            ),
            SizedBox(height: Responsive.space(context, 12)),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _pincodeController,
                    style: AppTextStyles.inputText(context),
                    decoration: _fieldDecoration(
                      label: 'Pincode',
                      icon: Icons.pin_drop_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                  ),
                ),
                SizedBox(width: Responsive.space(context, 12)),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isCheckingPincode ? null : _checkPincode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCheckingPincode
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Check',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            if (_pincodeStatusMessage != null)
              Padding(
                padding: EdgeInsets.only(top: Responsive.space(context, 10)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _isPincodeValid
                        ? const Color(0xFFF0F9F1)
                        : const Color(0xFFFDF0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          (_isPincodeValid
                                  ? AppColors.primaryGreen
                                  : AppColors.errorRed)
                              .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPincodeValid
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: _isPincodeValid
                            ? AppColors.primaryGreen
                            : AppColors.errorRed,
                        size: 18,
                      ),
                      SizedBox(width: Responsive.space(context, 8)),
                      Expanded(
                        child: Text(
                          _pincodeStatusMessage!,
                          style: TextStyle(
                            color: _isPincodeValid
                                ? AppColors.primaryGreen
                                : AppColors.errorRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: Responsive.space(context, 16)),
            _sectionLabel(
              context,
              Icons.calendar_today_outlined,
              'DELIVERY DATE & TIME',
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDeliveryDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppColors.primaryGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDeliveryDate != null
                                  ? '${_selectedDeliveryDate!.toLocal().toString().split(' ')[0]}'
                                  : 'Select Date',
                              style: TextStyle(
                                color: _selectedDeliveryDate != null
                                    ? AppColors.textDark
                                    : AppColors.textGray,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.space(context, 10)),
                Expanded(
                  child: InkWell(
                    onTap: _selectDeliveryTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.primaryGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDeliveryTime != null
                                  ? _formatTimeForDisplay(
                                      _selectedDeliveryTime!,
                                    )
                                  : 'Select Time',
                              style: TextStyle(
                                color: _selectedDeliveryTime != null
                                    ? AppColors.textDark
                                    : AppColors.textGray,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_vehicles.isNotEmpty) ...[
              SizedBox(height: Responsive.space(context, 24)),
              _sectionLabel(
                context,
                Icons.local_shipping_outlined,
                'SELECT DELIVERY VEHICLE',
              ),
              ...List.generate(_vehicles.length, (i) {
                final vehicle = _vehicles[i];
                final selected =
                    _selectedVehicle?.vehicleNumber == vehicle.vehicleNumber;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: Responsive.space(context, 10),
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedVehicle = vehicle),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF0F9F1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryGreen
                              : AppColors.inputBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryGreen
                                  : const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.local_shipping_rounded,
                              size: 20,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textGray,
                            ),
                          ),
                          SizedBox(width: Responsive.space(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.vehicleName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${vehicle.vehicleNumber} • ${vehicle.driverName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Capacity: ${vehicle.maxCapacityKg} kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: selected
                                ? AppColors.primaryGreen
                                : AppColors.inputBorder,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            SizedBox(height: Responsive.space(context, 12)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.inputBorder),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.space(context, 12)),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Place Your Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
