import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_request_page.dart';

class RequestDetailsPage extends StatefulWidget {
  @override
  _RequestDetailsPageState createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  List<dynamic> requestData = [];
  List<dynamic> filteredData = [];
  bool isLoading = true;
  bool hasError = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRequestDetails();
    searchController.addListener(() {
      filterSearchResults(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchRequestDetails() async {
    final url = Uri.parse('https://ukm.edu.pk/project9/public/api/req_res_admin');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData.containsKey('alldata') && jsonData['alldata'] is List) {
          setState(() {
            requestData = jsonData['alldata'];
            filteredData = jsonData['alldata'];
            isLoading = false;
            hasError = false;
          });
        } else {
          setState(() {
            isLoading = false;
            hasError = true;
          });
          throw Exception('Invalid response format');
        }
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        throw Exception('Failed to fetch data from server');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error fetching data: $e');
    }
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredData = requestData;
      });
    } else {
      setState(() {
        filteredData = requestData
            .where((item) => (item['request_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }@override
Widget build(BuildContext context) {
  final navyBlue = Color(0xFF001F54);
  final lightNavyBlue = Color(0xFFE8F1FF); // Light blue for accents

  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Request Details',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: navyBlue,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by request name',
              prefixIcon: Icon(Icons.search, color: navyBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: navyBlue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: lightNavyBlue,
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: navyBlue),
                )
              : hasError
                  ? Center(
                      child: Text(
                        'Failed to load data. Please try again later.',
                        style: TextStyle(fontSize: 16, color: navyBlue),
                      ),
                    )
                  : filteredData.isEmpty
                      ? Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(fontSize: 16, color: navyBlue),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            final item = filteredData[index];

                            final requestId = item['id'].toString();
                            final departmentName =
                                item['department_name'] ?? 'No Department';
                            final requestName =
                                item['request_name'] ?? 'No Request Name';
                            final paymentRequired =
                                item['payment_required'] ?? 'No';
                            final paymentAmount =
                                item['payment_amount'] ?? 'NA';
                            final requestTime =
                                item['request_time'] ?? 'No Time';
                            final officerAssigned =
                                item['officer_assigned'] ?? 'No';

                            return Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: navyBlue, width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        requestName,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: navyBlue,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.business, color: navyBlue),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Department: $departmentName',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.payment, color: navyBlue),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Payment Required: $paymentRequired',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.attach_money,
                                              color: navyBlue),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Payment Amount: $paymentAmount',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time,
                                              color: navyBlue),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Request Time: $requestTime',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.person, color: navyBlue),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Officer Assigned: $officerAssigned',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UserRequestPage(
                                                  requestId: requestId,
                                                  requestName: requestName,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: navyBlue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                          ),
                                          child: Text(
                                            'Apply',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    ),
  );
}
}