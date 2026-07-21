import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/api_client.dart';
import '../core/refresh_notifier.dart';

class ManualAddVisitorScreen extends StatefulWidget {
  final String? eventId;
  final String? eventName;
  const ManualAddVisitorScreen({super.key, this.eventId, this.eventName});

  @override
  State<ManualAddVisitorScreen> createState() => _ManualAddVisitorScreenState();
}

class _ManualAddVisitorScreenState extends State<ManualAddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedLookingFor;
  String? _decisionMaker;

  final List<String> _categories = [
    'Technology',
    'Manufacturing',
    'Services',
    'Retail',
    'Healthcare',
    'Education',
    'Other'
  ];

  final List<String> _lookingForOptions = [
    'Partnership',
    'Investment',
    'Buying Products',
    'Networking',
    'Employment',
    'Other'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    String? eventId = widget.eventId;
    if (eventId == null) {
      final eventJson = await ApiClient.getEventJson();
      if (eventJson != null) {
        final event = jsonDecode(eventJson);
        eventId = event['id']?.toString();
      }
    }

    final data = {
      "event_id": eventId,
      "visitor": {
        "full_name": _nameCtrl.text.trim(),
        "mobile_number": _mobileCtrl.text.trim(),
        "location": _locationCtrl.text.trim(),
        "business_category": _selectedCategory,
        "looking_for": _selectedLookingFor,
        "decision_maker": _decisionMaker == 'Yes',
        "reg_type": "Manual",
        "mobile_verified": true
      },
      "notes": _notesCtrl.text.trim()
    };

    final result = await ApiClient.createManualLead(data);

    if (mounted) {
      setState(() => _loading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead created successfully')),
        );
        RefreshNotifier.refreshLeads();
        Navigator.pop(context, true);
      } else {
        String error = result.error ?? 'Failed to create lead';
        if (result.data != null && result.data['already_scanned'] == true) {
          error = "Visitor already exists for this stall.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add Lead'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'Full Name *',
                      hint: 'Enter full name',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Full name is required' : null,
                    ),
                    _buildTextField(
                      controller: _mobileCtrl,
                      label: 'Mobile Number *',
                      hint: 'Enter 10 digit number',
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                        if (v.trim().length != 10) return 'Enter exactly 10 digits';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _locationCtrl,
                      label: 'Location / City *',
                      hint: 'Enter location or city',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Location is required' : null,
                    ),
                    
                    const SizedBox(height: 10),
                    const Text(
                      'Business Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildDropdown(
                      label: 'Business Category *',
                      value: _selectedCategory,
                      items: _categories,
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? 'Please select a category' : null,
                    ),
                    _buildDropdown(
                      label: 'Looking For *',
                      value: _selectedLookingFor,
                      items: _lookingForOptions,
                      onChanged: (v) => setState(() => _selectedLookingFor = v),
                      validator: (v) => v == null ? 'Please select an option' : null,
                    ),
                    _buildDropdown(
                      label: 'Decision Maker? *',
                      value: _decisionMaker,
                      items: ['Yes', 'No'],
                      onChanged: (v) => setState(() => _decisionMaker = v),
                      validator: (v) => v == null ? 'Please select an option' : null,
                    ),

                    _buildTextField(
                      controller: _notesCtrl,
                      label: 'Notes (Optional)',
                      hint: 'Enter any additional notes',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Lead',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? prefixText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              counterText: "",
              hintText: hint,
              prefixText: prefixText,
              prefixStyle: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
