import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final password = TextEditingController();
  final state = TextEditingController();
  final district = TextEditingController();
  final city = TextEditingController();

  bool loading = false;

  // 🔥 Generate unique patient ID
  String generatePatientId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rand = Random();
    return List.generate(12, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> register() async {

    // ✅ VALIDATION
    if (firstName.text.isEmpty ||
        lastName.text.isEmpty ||
        password.text.isEmpty ||
        state.text.isEmpty ||
        district.text.isEmpty ||
        city.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    String patientId = generatePatientId();

    final url = Uri.parse(
        "${ApiService.endpoint}/databases/${ApiService.databaseId}/collections/${ApiService.patientsCollectionId}/documents"
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-Appwrite-Project": ApiService.projectId,
        },
        body: jsonEncode({
          "documentId": "unique()",
          "data": {
            "patientId": patientId,
            "firstName": firstName.text,
            "lastName": lastName.text,
            "password": password.text,
            "state": state.text,
            "district": district.text,
            "city": city.text,
            "role": "patient"
          }
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: Text("Your Patient ID: $patientId"),
          ),
        );
      } else {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration failed")),
        );
      }

    } catch (e) {
      setState(() => loading = false);
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            TextField(
              controller: firstName,
              decoration: const InputDecoration(labelText: "First Name"),
            ),

            TextField(
              controller: lastName,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),

            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            TextField(
              controller: state,
              decoration: const InputDecoration(labelText: "State"),
            ),

            TextField(
              controller: district,
              decoration: const InputDecoration(labelText: "District"),
            ),

            TextField(
              controller: city,
              decoration: const InputDecoration(labelText: "City"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : register,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Register"),
            )

          ],
        ),
      ),
    );
  }
}
