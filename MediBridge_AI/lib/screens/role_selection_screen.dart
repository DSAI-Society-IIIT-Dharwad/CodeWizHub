import 'package:flutter/material.dart';
import 'patient_login_screen.dart';
import 'doctor_login_screen.dart';
import 'student_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_hospital, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('MediBridge AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Select your role to continue', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 48),
              _roleButton(context, 'Continue as Patient', Icons.person, Colors.blue, const PatientLoginScreen()),
              const SizedBox(height: 16),
              _roleButton(context, 'Continue as Doctor', Icons.medical_services, Colors.green, const DoctorLoginScreen()),
              const SizedBox(height: 16),
              _roleButton(context, 'Continue as Student', Icons.school, Colors.orange, const StudentLoginScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(BuildContext context, String label, IconData icon, Color color, Widget screen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
