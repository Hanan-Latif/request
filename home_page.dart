import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // To parse JSON data
import 'request_details_page.dart';
import 'create_request_form_page.dart'; // Import the page for the custom complaint form
import 'task_form_page.dart'; // Import the new task form page
import 'admin_page.dart';

class HomePage extends StatelessWidget {
  Future<List<dynamic>> fetchComplaintData() async {
    try {
      final url = Uri.parse(
          'https://ukm.edu.pk/project9/public/api/cms_requests/fetch?key=value');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] is List) {
          return data['data'];
        } else {
          print('Unexpected response format: $data');
          throw Exception('Unexpected response format. Expected "data" field with a list.');
        }
      } else {
        throw Exception('Failed to fetch data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching complaints: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF001F54),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.add,
                    label: 'New Complaint',
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestDetailsPage(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16), // Space between cards
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.list,
                    label: 'My Complaint',
                    color: Colors.blueAccent,
                    onTap: () async {
                      try {
                        List<dynamic> complaintData = await fetchComplaintData();
                        print('Fetched complaint data: $complaintData');

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (BuildContext context) {
                            return DraggableScrollableSheet(
                              expand: false,
                              initialChildSize: 0.6,
                              maxChildSize: 0.9,
                              builder: (_, controller) => Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'My Complaints',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF001F54),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: controller,
                                        itemCount: complaintData.length,
                                        itemBuilder: (context, index) {
                                          var complaint = complaintData[index];

                                          var id = complaint['id'] ?? 'N/A';
                                          var requestSubId = complaint['request_subb_id'] ?? 'N/A';
                                          var requestType = complaint['request_type'] ?? 'N/A';
                                          var details = complaint['details'] ?? 'No details available';
                                          var attachment = complaint['attachment'] ?? 'No attachment';
                                          var fee = complaint['fee'] ?? 'N/A';
                                          var requestTime = complaint['request_time'] ?? 'N/A';
                                          var remainingTime = complaint['remaining_time'] ?? 'N/A';
                                          var status = complaint['status'] ?? 'Pending'; // Adding status here

                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                            margin: EdgeInsets.symmetric(vertical: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
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
                                                        'Sub ID: $requestSubId',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Type: $requestType',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF001F54),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Details: $details',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Attachment: $attachment',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Fee: $fee',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Request Time: $requestTime',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.teal,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Remaining Time: $remainingTime',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Status: $status', // Display the status here
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.orange,
                                                    ),
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
                          },
                        );
                      } catch (e) {
                        print('Error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to load complaints: $e'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.settings_suggest,
                    label: 'Custom Complaint',
                    color: const Color.fromARGB(255, 189, 194, 109),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateRequestFormPage(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16), // Space between cards
                Expanded(
                  child: _buildCard(
                    context,
                    icon: Icons.task,
                    label: 'Add Task',
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskFormPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCard(
              context,
              icon: Icons.admin_panel_settings,
              label: 'Admin Page',
              color: Colors.purpleAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        color: color,
        child: Container(
          width: MediaQuery.of(context).size.width / 2.5,
          height: 120,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
