import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _selectedStatus = 'All Requests';
  List<dynamic> _requests = [];
  Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final url = Uri.parse('https://ukm.edu.pk/project9/public/api/cms_requests/fetch');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] is List) {
          setState(() {
            _requests = data['data'];
            // Initialize controllers for remarks
            _remarksControllers = {
              for (var request in _requests) request['id'].toString(): TextEditingController()
            };
          });
        } else {
          print('Error: Unexpected response format.');
        }
      } else {
        print('Error fetching requests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  List<dynamic> _filterRequests() {
    if (_selectedStatus == 'All Requests') {
      return _requests;
    } else {
      return _requests.where((request) {
        return request['status'] == _selectedStatus;
      }).toList();
    }
  }

  Future<void> _updateRequestStatus(String requestId, String newStatus, String remarks) async {
    if (requestId.isEmpty || remarks.isEmpty || newStatus.isEmpty) {
      print('Error: Missing required fields.');
      return;
    }

    final url = Uri.parse('https://ukm.edu.pk/project9/public/api/request-action');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'request_id': requestId,  // Ensure this is a string
          'remark': remarks,  // Ensure this is a string
          'status': newStatus,
        }),
      );

      // Log the request body for debugging
      print('Request Body: ${json.encode({
        'request_id': requestId,
        'remark': remarks,
        'status': newStatus,
      })}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('Request updated successfully.');
          // Update local state and refresh the requests
          _fetchRequests();
        } else {
          print('Error: ${data['message']}');
        }
      } else {
        // Log the response body to check the error message
        print('Error updating request: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF001F54),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown to filter requests
            DropdownButton<String>(
              value: _selectedStatus,
              items: ['All Requests', 'Accepted', 'Pending', 'Rejected']
                  .map((status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            SizedBox(height: 16),
            // List of requests
            Expanded(
              child: ListView.builder(
                itemCount: _filterRequests().length,
                itemBuilder: (context, index) {
                  var request = _filterRequests()[index];
                  var id = request['id'].toString();  // Ensure this is a String
                  var requestType = request['request_type'] ?? 'N/A';
                  var details = request['details'] ?? 'No details available';
                  var status = request['status'] ?? 'Pending';

                  // Ensure remarks controller is initialized
                  _remarksControllers.putIfAbsent(id, () => TextEditingController());

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Centered "Type" text at the top
                          Center(
                            child: Text(
                              'Type: $requestType',
                              style: TextStyle(
                                fontSize: 20, // Larger font size
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001F54),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Request details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Request ID: $id',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF001F54),
                                ),
                              ),
                              Text(
                                'Status: $status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'Accepted'
                                      ? Colors.green
                                      : status == 'Rejected'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Details: $details',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 16),
                          // Remarks input field
                          TextField(
                            controller: _remarksControllers[id],
                            decoration: InputDecoration(
                              labelText: 'Remarks',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onChanged: (value) {
                              // No need to update other cards
                            },
                          ),
                          SizedBox(height: 16),
                          // Buttons to update status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statusButton('Accept', Colors.green, () {
                                String remarks = _remarksControllers[id]?.text ?? '';
                                if (remarks.isNotEmpty) {
                                  _updateRequestStatus(id, 'Accepted', remarks);
                                } else {
                                  print('Remarks cannot be empty');
                                }
                              }),
                              _statusButton('Reject', Colors.red, () {
                                String remarks = _remarksControllers[id]?.text ?? '';
                                if (remarks.isNotEmpty) {
                                  _updateRequestStatus(id, 'Rejected', remarks);
                                } else {
                                  print('Remarks cannot be empty');
                                }
                              }),
                              _statusButton('Pending', Colors.orange, () {
                                String remarks = _remarksControllers[id]?.text ?? '';
                                if (remarks.isNotEmpty) {
                                  _updateRequestStatus(id, 'Pending', remarks);
                                } else {
                                  print('Remarks cannot be empty');
                                }
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
