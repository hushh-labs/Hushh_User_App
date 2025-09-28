import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_event.dart';
import '../bloc/checkout_state.dart';
import '../../domain/entities/checkout_entity.dart';
import 'payment_selection_page.dart';

class CheckoutFormPage extends StatefulWidget {
  const CheckoutFormPage({super.key});

  @override
  State<CheckoutFormPage> createState() => _CheckoutFormPageState();
}

class _CheckoutFormPageState extends State<CheckoutFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;

  // Track which fields are currently being edited to prevent overwriting
  final Set<String> _editingFields = <String>{};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCheckoutData();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressLine1Controller = TextEditingController();
    _addressLine2Controller = TextEditingController();
    _cityController = TextEditingController();
    _pincodeController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
  }

  void _loadCheckoutData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<CheckoutBloc>().add(LoadCheckoutDataEvent(user.uid));
    }
  }

  void _updateFormFields(CheckoutEntity data) {
    // Only update fields that are not currently being edited
    if (!_editingFields.contains('fullName')) {
      _fullNameController.text = data.fullName ?? '';
    }
    if (!_editingFields.contains('phoneNumber')) {
      _phoneController.text = data.phoneNumber ?? '';
    }
    if (!_editingFields.contains('email')) {
      _emailController.text = data.email ?? '';
    }
    if (!_editingFields.contains('addressLine1')) {
      _addressLine1Controller.text = data.addressLine1 ?? '';
    }
    if (!_editingFields.contains('addressLine2')) {
      _addressLine2Controller.text = data.addressLine2 ?? '';
    }
    if (!_editingFields.contains('city')) {
      _cityController.text = data.city ?? '';
    }
    if (!_editingFields.contains('pincode')) {
      _pincodeController.text = data.pincode ?? '';
    }
    if (!_editingFields.contains('state')) {
      _stateController.text = data.state ?? '';
    }
    if (!_editingFields.contains('country')) {
      _countryController.text = data.country ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Checkout Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutLoaded) {
            // Only update form fields on initial load, not on every field update
            _updateFormFields(state.checkoutData);
          } else if (state is CheckoutSubmitted) {
            _navigateToPaymentSelection();
          } else if (state is CheckoutError) {
            _showErrorMessage(state.message);
          }
        },
        child: BlocBuilder<CheckoutBloc, CheckoutState>(
          builder: (context, state) {
            if (state is CheckoutLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA342FF)),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Personal Information'),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _fullNameController,
                            label: 'Full Name',
                            fieldName: 'fullName',
                            isRequired: true,
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            fieldName: 'phoneNumber',
                            isRequired: true,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _emailController,
                            label: 'Email Address',
                            fieldName: 'email',
                            isRequired: true,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Shipping Address'),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _addressLine1Controller,
                            label: 'Address Line 1',
                            fieldName: 'addressLine1',
                            isRequired: true,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _addressLine2Controller,
                            label: 'Address Line 2 (Optional)',
                            fieldName: 'addressLine2',
                            isRequired: false,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _cityController,
                                  label: 'City',
                                  fieldName: 'city',
                                  isRequired: true,
                                  prefixIcon: Icons.location_city_outlined,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _pincodeController,
                                  label: 'Pincode',
                                  fieldName: 'pincode',
                                  isRequired: true,
                                  prefixIcon: Icons.markunread_mailbox_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _stateController,
                            label: 'State',
                            fieldName: 'state',
                            isRequired: true,
                            prefixIcon: Icons.map_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _countryController,
                            label: 'Country',
                            fieldName: 'country',
                            isRequired: true,
                            prefixIcon: Icons.public_outlined,
                          ),
                          const SizedBox(
                            height: 100,
                          ), // Space for floating button
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomSection(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String fieldName,
    required bool isRequired,
    required IconData prefixIcon,
    TextInputType? keyboardType,
  }) {
    final focusNode = FocusNode();

    // Listen to focus changes to track when user stops editing
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _editingFields.remove(fieldName);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onTap: () {
          // Mark field as being edited
          _editingFields.add(fieldName);
        },
        onChanged: (value) {
          context.read<CheckoutBloc>().add(
            UpdateCheckoutFieldEvent(fieldName, value),
          );
        },
        onFieldSubmitted: (value) {
          // Remove from editing fields when user finishes editing
          _editingFields.remove(fieldName);
        },
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                if (fieldName == 'email' &&
                    !RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF666666)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: const Text(
              'Continue to Payment',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<CheckoutBloc>().add(SubmitCheckoutDataEvent(user.uid));
      }
    }
  }

  void _navigateToPaymentSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentSelectionPage()),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
