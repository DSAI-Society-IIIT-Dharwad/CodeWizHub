import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import 'patient_dashboard_screen.dart';
import 'package:flutter/services.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String _selectedState = 'Karnataka';
  String _selectedDistrict = 'Bengaluru Urban';

  bool _loading = false;
  String _error = '';

  final List<String> _states = [
    'Karnataka',
    'Maharashtra',
    'Tamil Nadu',
    'Kerala',
    'Andhra Pradesh',
    'Telangana',
    'Delhi',
    'Gujarat'
  ];

  final Map<String, List<String>> _districts = {
    'Karnataka': ['Bengaluru Urban', 'Mysuru', 'Mangaluru', 'Hubballi', 'Belagavi'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Tiruchirappalli'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam'],
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
  };

  String _validatePassword(String password) {
    if (password.length < 5) return 'At least 5 characters required';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'At least 1 uppercase letter required';
    if (!password.contains(RegExp(r'[0-9]'))) return 'At least 1 digit required';
    if (!password.contains(RegExp(r'[!@#$%^&*]'))) return 'At least 1 special character required';
    return '';
  }

  Future<void> _register() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _dobController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }


    final passError = _validatePassword(_passController.text);
    if (passError.isNotEmpty) {
      setState(() => _error = passError);
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final result = await AuthService().registerPatient(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      password: _passController.text,
      state: _selectedState,
      district: _selectedDistrict,
      city: _cityController.text.trim(),
      dob: _dobController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    setState(() => _loading = false);

    if (result['success']) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Registration Successful!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your Patient ID is:'),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          result['patientId'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: result['patientId']),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Patient ID copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  '⚠️ Save this ID carefully. You will need it to login.',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final loginResult = await AuthService().loginPatient(
                    patientId: result['patientId'],
                    password: _passController.text,
                  );

                  if (loginResult['success'] && mounted) {
                    await SessionManager.saveSession(
                        loginResult['user'], 'patient');

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientDashboardScreen(),
                      ),
                    );
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() => _error = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: '+91XXXXXXXXXX',
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _dobController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Select DOB',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );

                if (pickedDate != null) {
                  setState(() {
                    _dobController.text =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  });
                }
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: const InputDecoration(labelText: 'State'),
              items: _states
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedState = val!;
                  _selectedDistrict = _districts[val]!.first;
                });
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: const InputDecoration(labelText: 'District'),
              items: (_districts[_selectedState] ?? [])
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedDistrict = val!),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            const SizedBox(height: 12),

            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
