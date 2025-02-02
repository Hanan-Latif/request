
import 'package:flutter/material.dart';

class StatusScreen extends StatelessWidget {
  final Map<String, List<dynamic>> categorizedRequests;

  StatusScreen({required this.categorizedRequests});

  @override
  Widget build(BuildContext context) {
    final navyBlue = Color(0xFF001F54);

    return Scaffold(
      appBar: AppBar(
        title: Text('Requests by Status', style: TextStyle(color: Colors.white)),
        backgroundColor: navyBlue,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: navyBlue,
              tabs: [
                Tab(text: 'Accepted'),
                Tab(text: 'Rejected'),
                Tab(text: 'Pending'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: ['Accepted', 'Rejected', 'Pending'].map((status) {
                  final requests = categorizedRequests[status] ?? [];
                  return requests.isEmpty
                      ? Center(child: Text('No $status requests found'))
                      : ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request = requests[index];
                            return ListTile(
                              title: Text(request['request_type'] ?? 'Request'),
                              subtitle: Text('Status: $status'),
                            );
                          },
                        );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
