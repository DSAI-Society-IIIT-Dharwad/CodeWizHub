import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'patient_login_screen.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});
  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();

  // Controllers
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // State
  bool _loading = false;
  String _error = '';
  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;
  int _currentPage = 0;

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
      _error = '';
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ── Calculate age from DOB string ──
  int _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  // ── Mask phone number for display ──
  String _maskPhone(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
  }

  // ── Password validation ──
  String _validatePassword(String password) {
    if (password.length < 5) return 'At least 5 characters required';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'At least 1 uppercase letter required';
    if (!password.contains(RegExp(r'[0-9]'))) return 'At least 1 digit required';
    if (!password.contains(RegExp(r'[!@#\$%^&*]'))) return 'At least 1 special character (!@#\$%^&*) required';
    return '';
  }

  // ── STEP 1: Search by phone ──
  Future<void> _searchByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    final result = await _authService.getPatientsByPhone(phone);

    setState(() => _loading = false);

    if (!result['success']) {
      setState(() => _error = result['error']);
      return;
    }

    final patients = List<Map<String, dynamic>>.from(result['patients']);
    setState(() => _patients = patients);

    if (patients.length == 1) {
      // Only one patient → skip selection, go to DOB
      setState(() => _selectedPatient = patients.first);
      _goToPage(2); // skip page 1 (selection)
    } else {
      // Multiple patients → show selection
      _goToPage(1);
    }
  }

  // ── STEP 2: Patient selected ──
  void _selectPatient(Map<String, dynamic> patient) {
    setState(() => _selectedPatient = patient);
    _goToPage(2);
  }

  // ── STEP 3: Verify DOB ──
  Future<void> _verifyDOB() async {
    final enteredDOB = _dobController.text.trim();
    if (enteredDOB.isEmpty) {
      setState(() => _error = 'Please enter your date of birth');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    // Simulate slight delay for UX
    await Future.delayed(const Duration(milliseconds: 500));

    final isValid = _authService.verifyDOB(_selectedPatient!, enteredDOB);

    setState(() => _loading = false);

    if (!isValid) {
      setState(() => _error = 'Invalid details. Date of birth does not match.');
      return;
    }

    _goToPage(3);
  }

  // ── STEP 4: Reset password ──
  Future<void> _resetPassword() async {
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    final passError = _validatePassword(newPass);
    if (passError.isNotEmpty) {
      setState(() => _error = passError);
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    // Get the document $id (Appwrite internal ID)
    final documentId = _selectedPatient!['\$id'];

    final result = await _authService.updatePassword(
      documentId: documentId,
      newPassword: newPass,
    );

    setState(() => _loading = false);

    if (!result['success']) {
      setState(() => _error = result['error']);
      return;
    }

    // Show success and redirect
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Password Updated!'),
          ]),
          content: const Text('Your password has been reset successfully. Please login with your new password.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientLoginScreen()),
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  //                    UI PAGES
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Forgot ID / Password'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _goToPage(_currentPage - 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // manual navigation only
              children: [
                _buildPage1Phone(),
                _buildPage2SelectProfile(),
                _buildPage3VerifyDOB(),
                _buildPage4ResetPassword(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──
  Widget _buildProgressBar() {
    final steps = ['Phone', 'Profile', 'Verify', 'Reset'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.blue.shade50,
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentPage;
          final isDone = i < _currentPage;
          return Expanded(
            child: Row(
              children: [
                Column(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDone ? Colors.green : (isActive ? Colors.blue : Colors.grey.shade300),
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text('${i + 1}', style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 2),
                  Text(steps[i], style: TextStyle(
                      fontSize: 9,
                      color: isActive ? Colors.blue : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                ]),
                if (i < steps.length - 1)
                  Expanded(child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isDone ? Colors.green : Colors.grey.shade300,
                  )),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Page 1: Enter Phone ──
  Widget _buildPage1Phone() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.phone_android, size: 60, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('Find Your Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Enter the WhatsApp number linked to your account.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 15,
            decoration: const InputDecoration(
              labelText: 'WhatsApp Number',
              hintText: 'e.g. 9876543210',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error, style: const TextStyle(color: Colors.red))),
              ]),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loading ? null : _searchByPhone,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Continue', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Select Profile ──
  Widget _buildPage2SelectProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.people, size: 60, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('Select Your Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Multiple accounts found for ${_maskPhone(_phoneController.text)}. Who are you?',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ..._patients.map((patient) {
            final age = _calculateAge(patient['dob']);
            final name = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
            final city = patient['city'] ?? '';
            return GestureDetector(
              onTap: () => _selectPatient(patient),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                  boxShadow: [BoxShadow(color: Colors.blue.shade50, blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Age $age${city.isNotEmpty ? ' · $city' : ''}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ])),
                  const Icon(Icons.chevron_right, color: Colors.blue),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Page 3: Verify DOB ──
  Widget _buildPage3VerifyDOB() {
    final name = _selectedPatient != null
        ? '${_selectedPatient!['firstName'] ?? ''} ${_selectedPatient!['lastName'] ?? ''}'.trim()
        : '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.verified_user, size: 60, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('Verify Identity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Enter the date of birth for $name to confirm your identity.',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
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
          const SizedBox(height: 8),
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error, style: const TextStyle(color: Colors.red))),
              ]),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loading ? null : _verifyDOB,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 4: Reset Password ──
  Widget _buildPage4ResetPassword() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.lock_reset, size: 60, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Reset Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Show Patient ID with copy button
          if (_selectedPatient != null) ...[
            const Text('Your Patient ID:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedPatient!['patientId'] ?? '',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold,
                      color: Colors.blue, letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    tooltip: 'Copy Patient ID',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _selectedPatient!['patientId'] ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Patient ID copied!'), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          TextField(
            controller: _newPassController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
              helperText: 'Min 5 chars, 1 uppercase, 1 digit, 1 special char',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPassController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error, style: const TextStyle(color: Colors.red))),
              ]),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loading ? null : _resetPassword,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update Password', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}


