import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import 'patient_register_screen.dart';
import 'patient_dashboard_screen.dart';
import 'forgot_screen.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});
  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() { _loading = true; _error = ''; });
    final result = await AuthService().loginPatient(
      patientId: _idController.text.trim(),
      password: _passController.text,
    );
    setState(() => _loading = false);
    if (result['success']) {
      await SessionManager.saveSession(result['user'], 'patient');
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientDashboardScreen()));
    } else {
      setState(() => _error = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Patient ID', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading ? const CircularProgressIndicator() : const Text('Login'),
          )),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientRegisterScreen())),
            child: const Text("Don't have an account? Register here"),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotScreen()),
            ),
            child: const Text(
              'Forgot Patient ID / Password?',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ]),
      ),
    );
  }
}
