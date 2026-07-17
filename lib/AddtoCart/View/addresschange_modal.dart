// lib/AddtoCart/View/addresschange_modal.dart - Simplified version

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/AddtoCart/View/addtocart_view.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
    _loadVehicles();
    _selectedDeliveryDate = DateTime.now().add(const Duration(days: 1));
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
      AlertDialog(
        title: const Text('📍 Delivery Distance Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please note:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '• The delivery distance affects the final price',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              '• Longer distances may incur additional charges',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              '• You can review the delivery charge before placing your order',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Distance may increase the delivery charge',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('I Understand'),
          ),
        ],
      ),
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

    setState(() => _isLoading = true);

    try {
      final address = AddressModel(
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        pincode: _pincodeController.text,
      );

      // Update address in controller
      await widget.controller.updateAddress(address);

      // Save vehicle selection
      if (_selectedVehicle != null) {
        widget.controller.selectedVehicle.value = _selectedVehicle;
      }

      // Save delivery date
      final dateString = _selectedDeliveryDate!
          .toIso8601String()
          .split('T')
          .first;
      widget.controller.selectedDeliveryDate.value = dateString;

      // ✅ CHECK DELIVERY AVAILABILITY - ONLY HERE
      final checkoutResult = await widget.controller.processCheckout(
        pincode: _pincodeController.text,
        deliveryDate: dateString,
      );

      if (checkoutResult == null) {
        if (!mounted) return;
        Get.back(result: false);
        return;
      }

      if (!checkoutResult.deliveryAvailable) {
        // ❌ Delivery not available - show message
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
                  Get.back(); // Close dialog
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
        return; // Stay in modal
      }

      // ✅ Delivery available - show delivery charge breakdown
      _showDeliveryChargeBreakdown(checkoutResult);

      if (!mounted) return;
      // ✅ Back to cart page
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update address: $e');
      setState(() => _isLoading = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeliveryChargeBreakdown(CheckoutResponse response) {
    final config = response.deliveryConfig;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Delivery Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      response.message,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delivery Charge Breakdown:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              '📍 Distance',
              '${config.totalDistanceKm.toStringAsFixed(1)} km',
            ),
            _buildInfoRow('Free Limit', '${config.freeDistanceLimitKm} km'),
            _buildInfoRow(
              'Extra Distance',
              '${config.extraDistance.toStringAsFixed(1)} km',
            ),
            _buildInfoRow(
              'Charge per Extra KM',
              '₹${config.chargePerExtraKm.toStringAsFixed(0)}',
            ),
            const Divider(),
            _buildInfoRow(
              'Delivery Charge',
              '₹${response.paymentSummary.deliveryCharge.toStringAsFixed(0)}',
              isTotal: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            // onPressed: () => CartScreen(),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Proceed to Cart',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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

            // ── Delivery Date Picker ──
            SizedBox(height: Responsive.space(context, 16)),
            _sectionLabel(
              context,
              Icons.calendar_today_outlined,
              'DELIVERY DATE',
            ),
            InkWell(
              onTap: _selectDeliveryDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDeliveryDate != null
                            ? '${_selectedDeliveryDate!.toLocal().toString().split(' ')[0]}'
                            : 'Select Delivery Date',
                        style: TextStyle(
                          color: _selectedDeliveryDate != null
                              ? AppColors.textDark
                              : AppColors.textGray,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textGray),
                  ],
                ),
              ),
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
