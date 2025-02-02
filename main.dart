import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

// Entry point for the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Request Management',
      theme: ThemeData(
        primaryColor: Colors.brown[800],
        scaffoldBackgroundColor: Colors.brown[50],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: isLoggedIn ? HomePage() : const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    const String url = 'https://devtechtop.com/store/public/login';
    final Map<String, String> data = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        body: data,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      setState(() {
        _isLoading = false;
      });

      final responseBody = response.body;
      print('Raw Response: $responseBody');

      if (response.statusCode == 200) {
        if (responseBody.contains('This user does not exist')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This user does not exist')),
          );
        } else {
          final decodedResponse = jsonDecode(responseBody);

          if (decodedResponse is Map && decodedResponse['status'] == 'success') {
            final List<dynamic> dataList = decodedResponse['data'];

            if (dataList.isNotEmpty) {
              final userData = dataList[0];

              final String name = userData['name']?.toString() ?? 'No Name';
              final String email = userData['email']?.toString() ?? 'No Email';
              final String degree = userData['degree']?.toString() ?? 'No Degree';
              final String shift = userData['shift']?.toString() ?? 'No Shift';
              final int? userId = int.tryParse(userData['id']?.toString() ?? '');

              if (userId == null) {
                print('Error: userId is invalid or null.');
                return;
              }

              // Save user details and login status to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('userId', userId);
              await prefs.setString('userEmail', email);
              await prefs.setString('userName', name);
              await prefs.setString('userDegree', degree);
              await prefs.setString('userShift', shift);
              await prefs.setBool('isLoggedIn', true); // Set login status

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login successful!')),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            }
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.brown[600]),
                filled: true,
                fillColor: Colors.brown[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.brown[300]!),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.brown[600]),
                filled: true,
                fillColor: Colors.brown[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.brown[300]!),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_emailController.text.isNotEmpty &&
                    _passwordController.text.isNotEmpty) {
                  _login();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in both fields')),
                  );
                }
              },
              child: const Text('Login'),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text(
                'Don\'t have an account? Sign up here',
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cellNoController = TextEditingController();
  String? _selectedShift = 'Morning'; // Default shift
  String? _selectedDegree = 'BS IT'; // Default degree
  bool _isLoading = false;

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    final nameRegExp = RegExp(r'^[A-Za-z\s]+$');
    if (!nameRegExp.hasMatch(value)) {
      return 'Name cannot contain numbers or special characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password should be at least 6 characters';
    }
    return null;
  }

  String? _validateCellNo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Cell number is required';
    }
    if (value.length != 11) {
      return 'Cell number must be 11 digits';
    }
    final cellNoRegExp = RegExp(r'^[0-9]+$');
    if (!cellNoRegExp.hasMatch(value)) {
      return 'Cell number must contain only digits';
    }
    return null;
  }

  Future<void> _submitForm() async {
    const String url = 'https://devtechtop.com/store/public/insert_user';
    final Map<String, String> data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'cell': _cellNoController.text.trim(),
      'shift': _selectedShift!,
      'degree': _selectedDegree!,
    };

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        body: data,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${decodedResponse['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating account')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.brown[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _validateName,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: _validatePassword,
                ),
                TextFormField(
                  controller: _cellNoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Cell No'),
                  validator: _validateCellNo,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedShift,
                  decoration: const InputDecoration(labelText: 'Shift'),
                  items: const [
                    DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                    DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                    DropdownMenuItem(value: 'Night', child: Text('Night')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedShift = newValue;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedDegree,
                  decoration: const InputDecoration(labelText: 'Degree'),
                  items: const [
                    DropdownMenuItem(value: 'BS IT', child: Text('BS IT')),
                    DropdownMenuItem(value: 'BS CS', child: Text('BS CS')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDegree = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
