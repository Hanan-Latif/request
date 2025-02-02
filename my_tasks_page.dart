import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyTasksPage extends StatefulWidget {
  @override
  _MyTasksPageState createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _users = [];
  int? _userId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id') ?? 28; // Dummy user_id 28
    });
    
    fetchTasks();
    fetchUsers();
  }

  Future<void> fetchTasks() async {
    final url = Uri.parse('https://devtechtop.com/student_request/public/api/select_tasks');
    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['tasks'] is List) {
          setState(() {
            _tasks = List<Map<String, dynamic>>.from(data['tasks']);
            _isLoading = false;
          });
        } else {
          throw Exception('Unexpected response format.');
        }
      } else {
        throw Exception('Failed to fetch tasks.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching tasks: $e';
      });
    }
  }

  Future<void> fetchUsers() async {
    final url = Uri.parse('https://devtechtop.com/store/public/api/all_user');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': _userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          setState(() {
             _users = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          throw Exception('Failed to load assignee data.');
        }
      } else {
        throw Exception('Failed to load assignee data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching assignees: $e');
    }
  }

  void _showAssigneeDialog(int taskIndex) async {
    List<int> selectedAssignees = _tasks[taskIndex]['assignees'] ?? [];
    final List<int>? result = await showDialog<List<int>>(
      context: context,
      builder: (context) => MultiSelectDialog(
        items: _users,
        initialSelectedValues: selectedAssignees,
      ),
    );

    if (result != null) {
      setState(() {
        _tasks[taskIndex]['assignees'] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF001F54),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Name: ${task['task_name']}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F54)),
                            ),
                            SizedBox(height: 8),
                            Text('Description: ${task['description']}', style: TextStyle(color: Color(0xFF001F54))),
                            SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showAssigneeDialog(index),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _tasks[index]['assignees'] != null && _tasks[index]['assignees'].isNotEmpty
                                      ? _tasks[index]['assignees'].map((id) => _users.firstWhere((user) => user['id'] == id, orElse: () => {'name': 'Unknown'})['name']).join(', ')
                                      : 'Select Assignees',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<int> initialSelectedValues;

  MultiSelectDialog({
    required this.items,
    required this.initialSelectedValues,
  });

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<int> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = widget.initialSelectedValues;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Assignees"),
      content: SingleChildScrollView(
        child: Column(
          children: widget.items.map((item) {
            return CheckboxListTile(
              title: Text(item['name']),
              value: _selectedValues.contains(item['id']),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _selectedValues.add(item['id']);
                  } else {
                    _selectedValues.remove(item['id']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedValues);
          },
          child: Text("Done"),
        ),
      ],
    );
  }
}
