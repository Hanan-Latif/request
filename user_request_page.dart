import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'status_screen.dart'; // Import the new screen for status management

class UserRequestPage extends StatefulWidget {
  final String requestId; // ID of the selected request
  final String requestName; // Name of the selected request

  UserRequestPage({required this.requestId, required this.requestName});

  @override
  _UserRequestPageState createState() => _UserRequestPageState();
}

class _UserRequestPageState extends State<UserRequestPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController remarksController = TextEditingController();
  bool isSubmitting = false;
  List<dynamic> relatedRequests = [];
  Map<String, List<dynamic>> categorizedRequests = {
    'Accepted': [],
    'Rejected': [],
    'Pending': []
  };

  Future<void> submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    final url = Uri.parse('https://ukm.edu.pk/project9/public/api/cms_requests');
    final body = {
      "request_type": widget.requestId,
      "details": descriptionController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('Your request has been submitted successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  fetchRelatedRequests();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        String errorMessage = responseData['errors']?['details']?[0] ??
            'Failed to submit the request.';
        showErrorDialog(errorMessage);
      }
    } catch (e) {
      showErrorDialog('An error occurred. Please try again later.');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> fetchRelatedRequests() async {
    final url = Uri.parse('https://ukm.edu.pk/project9/public/api/cms_requests/fetch');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          setState(() {
            relatedRequests = data['data'];
          });
        } else {
          print('Invalid data format');
        }
      } else {
        print('Failed to load related requests');
      }
    } catch (e) {
      print('Error fetching related requests: $e');
    }
  }

  Future<void> changeRequestStatus(String requestId, String status) async {
    final url = Uri.parse('https://ukm.edu.pk/project9/public/api/request-action');

    if (remarksController.text.isEmpty) {
      showErrorDialog('Remarks are required!');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final body = {
      'request_id': requestId,
      'status': status,
      'remark': remarksController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['errors'] == null) {
        setState(() {
          // Remove the request from the current list
          final updatedRequest = relatedRequests.firstWhere(
              (item) => item['id'].toString() == requestId,
              orElse: () => null);
          if (updatedRequest != null) {
            relatedRequests.removeWhere((item) => item['id'].toString() == requestId);

            // Add it to the categorized requests
            categorizedRequests[status]?.add(updatedRequest);
          }
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('Request status updated to $status successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        String errorMessage = responseData['errors']?['status']?[0] ??
            'Failed to update the status.';
        showErrorDialog(errorMessage);
      }
    } catch (e) {
      showErrorDialog('An error occurred. Please try again later.');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRelatedRequests();
  }

  @override
  Widget build(BuildContext context) {
    final navyBlue = Color(0xFF001F54);
    final lightNavyBlue = Color(0xFFE8F1FF);

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply Request', style: TextStyle(color: Colors.white)),
        backgroundColor: navyBlue,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatusScreen(
                    categorizedRequests: categorizedRequests,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Name:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyBlue),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: lightNavyBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: navyBlue),
                    ),
                    child: Text(
                      widget.requestName,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: navyBlue),
                      hintText: 'Enter a description for your request',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: navyBlue, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: isSubmitting
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Submit Request',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Show related requests
            Text(
              'Related Requests:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue),
            ),
            SizedBox(height: 8),
            relatedRequests.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: relatedRequests.map<Widget>((item) {
                      final requestId = item['id'].toString();
                      final departmentName = item['department_name'] ?? 'No Department';
                      final requestName = item['request_type'] ?? 'No Request Name';
                      final paymentRequired = item['payment_required'] ?? 'No';
                      final paymentAmount = item['payment_amount'] ?? 'NA';
                      final requestTime = item['request_time'] ?? 'No Time';
                      final officerAssigned = item['officer_assigned'] ?? 'No';
                      final status = item['status'] ?? 'Pending'; // Default status is Pending

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Request ID: $requestId', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Department: $departmentName'),
                              Text('Request Type: $requestName'),
                              Text('Payment Required: $paymentRequired'),
                              Text('Payment Amount: $paymentAmount'),
                              Text('Request Time: $requestTime'),
                              Text('Officer Assigned: $officerAssigned'),
                              SizedBox(height: 12),
                              Text('Status: $status', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              // Remarks TextField
                              TextField(
                                controller: remarksController,
                                decoration: InputDecoration(
                                  labelText: 'Enter Remarks',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => changeRequestStatus(requestId, 'Accepted'),
                                    child: Text('Accept'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => changeRequestStatus(requestId, 'Rejected'),
                                    child: Text('Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => changeRequestStatus(requestId, 'Pending'),
                                    child: Text('Pending'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
