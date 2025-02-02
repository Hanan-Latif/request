import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateRequestFormPage extends StatefulWidget {
  @override
  _CreateRequestFormPageState createState() => _CreateRequestFormPageState();
}

class _CreateRequestFormPageState extends State<CreateRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _department;
  String? _duration;
  bool _isPaymentRegistered = false;

  Future<void> submitRequest() async {
    const String apiUrl = "";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "re_name": _reNameController.text.trim(),
          "department": _department ?? '',
          "duration": _duration ?? '',
          "pay_request": _isPaymentRegistered ? 'Registered' : 'Not Registered',
          "amount": _amountController.text.trim(),
        },
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _clearForm();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Success"),
              content: Text(responseData['message']),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
          );
        } else {
          showErrorDialog("API Error: ${responseData['message']}");
        }
      } else {
        showErrorDialog("Failed to submit request. HTTP Error: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      print("Error: $e");
      print("StackTrace: $stackTrace");
      showErrorDialog("An error occurred. Please try again.");
    }
  }

  void _clearForm() {
    _reNameController.clear();
    _amountController.clear();
    setState(() {
      _department = null;
      _duration = null;
      _isPaymentRegistered = false;
    });
    _formKey.currentState?.reset();
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF001F54),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Request Name', _reNameController, 'Enter request name'),
              SizedBox(height: 16),
              _buildDropdownField(
                'Select Department',
                ['HR', 'IT', 'Finance'],
                (value) => setState(() => _department = value),
                _department,
              ),
              SizedBox(height: 16),
              _buildDropdownField(
                'Duration',
                ['12 hours', '24 hours', '72 hours', '1 week', '1 month'],
                (value) => setState(() => _duration = value),
                _duration,
              ),
              SizedBox(height: 16),
              _buildTextField('Amount', _amountController, 'Enter amount', isNumber: true),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Registered',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _isPaymentRegistered,
                    onChanged: (value) {
                      setState(() {
                        _isPaymentRegistered = value;
                      });
                    },
                    activeColor: Color(0xFF001F54),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    submitRequest();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF001F54),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: Text(
                  'Submit Request',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String errorText, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF001F54), fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF001F54), width: 2),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? errorText : null,
    );
  }

  Widget _buildDropdownField(String label, List<String> items, Function(String?) onChanged, String? selectedValue) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF001F54), fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF001F54), width: 2),
        ),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null || value.isEmpty ? 'Select $label' : null,
    );
  }
}
