import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_tasks_page.dart'; // Import the MyTasksPage

class TaskFormPage extends StatefulWidget {
  @override
  _TaskFormPageState createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  List<Map<String, dynamic>> _assigneeList = [];
  List<String> _selectedAssignees = [];
  String? _taskName;
  String? _description;
  int? _timeToAllocate;
  String? _unit;
  DateTime? _endDateTime;
  int? _userId;

  @override
  void initState() {
    super.initState();
    saveUserId(); // Save user_id as 28
    _getUserId(); // Get user_id from SharedPreferences
  }

  // Save user_id to SharedPreferences
  Future<void> saveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', 28); // Save user_id as 28
    print('User ID saved: 28');
  }

  // Retrieve user_id from SharedPreferences
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id'); // Retrieve the saved user_id
    });
    if (_userId != null) {
      fetchAssigneeList();
    }
  }

  // Fetch assignee list from the API
  Future<void> fetchAssigneeList() async {
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
            _assigneeList = List<Map<String, dynamic>>.from(data['data']);
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

  // Submit the task to the API
  Future<void> submitTask() async {
    if (_selectedAssignees.isEmpty || _description == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignee and Description are required')),
      );
      return;
    }

    final url = Uri.parse(
        'https://devtechtop.com/student_request/public/api/insert_add_task');
    final requestData = {
      'task_name': _taskName,
      'description': _description,
      'assignee': _selectedAssignees.join(', '),
      'time_to_allocate': _timeToAllocate?.toString(),
      'unit': _unit,
      'end_date_time': _endDateTime?.toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        body: json.encode(requestData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task added successfully')),
          );

          // After successfully adding the task, insert into the second API
          final taskId = data['task_id']; // Assuming the task ID is returned in the response
          await submitTaskUserValue(taskId);

          // Navigate to My Tasks Page after successful task submission
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyTasksPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${data['message']}')),
          );
        }
      } else {
        throw Exception('Failed to add task. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting task: $e')),
      );
    }
  }

  // Insert data into the insert_task_user_value API
  Future<void> submitTaskUserValue(int taskId) async {
    if (_selectedAssignees.isEmpty || _description == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignee and Description are required')),
      );
      return;
    }

    final userId = await _getUserIdFromAPI(); // Fetch user_id from API
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    final url = Uri.parse(
        'https://devtechtop.com/student_request/public/api/insert_task_user_value');
    final requestData = {
      'task_id': taskId,
      'user_id': userId, // Adding user_id
      'assignee': _selectedAssignees.join(', '),
      'description': _description,
    };

    try {
      final response = await http.post(
        url,
        body: json.encode(requestData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assignee data added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${data['message']}')),
          );
        }
      } else {
        throw Exception('Failed to add task assignee data. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting task assignee data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting assignee data: $e')),
      );
    }
  }

  // Fetch user_id from select_tasks API
  Future<int?> _getUserIdFromAPI() async {
    final url = Uri.parse('https://devtechtop.com/student_request/public/api/select_tasks');
    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] is Map) {
          return data['data']['user_id']; // Assuming the user_id is returned here
        } else {
          throw Exception('User ID not found in select_tasks response.');
        }
      } else {
        throw Exception('Failed to fetch user_id. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user_id: $e');
      return null;
    }
  }

  // Open the dialog to select multiple items
  Future<void> _showMultiSelectDialog() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Assignees'),
              content: SingleChildScrollView(
                child: Column(
                  children: _assigneeList.map((assignee) {
                    final isSelected = _selectedAssignees.contains(assignee['name']);
                    return ListTile(
                      title: Text(assignee['name']),
                      trailing: Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedAssignees.remove(assignee['name']);
                          } else {
                            _selectedAssignees.add(assignee['name']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedAssignees);
                  },
                  child: Text('Confirm'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, null); // Return null for cancel action
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedAssignees = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Task',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF001F54),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyTasksPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField('Task Name', (value) => _taskName = value, false),
            _buildTextField('Description', (value) => _description = value, true), // Required field
            _buildDropdownField(
              'Assign To',
              () async {
                await _showMultiSelectDialog();
              },
              _selectedAssignees.isEmpty
                  ? 'No Assignees Selected'
                  : _selectedAssignees.join(', '), // Required field
            ),
            _buildTextField('Time to Allocate', (value) => _timeToAllocate = int.tryParse(value!), false),
            _buildDropdownField(
              'Unit',
              () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    title: Text('Select Unit'),
                    children: ['days', 'hours', 'minutes']
                        .map(
                          (unit) => SimpleDialogOption(
                            child: Text(unit),
                            onPressed: () => Navigator.pop(context, unit),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _unit = result;
                  });
                }
              },
              _unit ?? 'Select Unit',
            ),
            _buildDateTimeField('End Date Time', (value) => _endDateTime = value, false),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitTask,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onChanged, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownField(String label, Function onTap, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => onTap(),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
          ),
          child: Text(value),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String label, Function(DateTime?) onChanged, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () async {
          final dateTime = await showDatePicker(
            context: context,
            initialDate: _endDateTime ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (dateTime != null) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(_endDateTime ?? DateTime.now()),
            );
            if (time != null) {
              onChanged(DateTime(
                dateTime.year,
                dateTime.month,
                dateTime.day,
                time.hour,
                time.minute,
              ));
            }
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label + (isRequired ? ' *' : ''),
            border: OutlineInputBorder(),
          ),
          child: Text(
            _endDateTime == null
                ? 'Select Date'
                : _endDateTime!.toLocal().toString(),
          ),
        ),
      ),
    );
  }
}
