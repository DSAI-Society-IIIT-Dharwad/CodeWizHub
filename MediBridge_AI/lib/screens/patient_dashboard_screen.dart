import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../services/consultation_service.dart';
import 'role_selection_screen.dart';
import 'consultation_detail_screen.dart';
import 'dart:convert';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});
  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> _consultations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await SessionManager.getSession();
    setState(() { userData = data; _loading = true; });

    final list = await ConsultationService()
        .getPatientConsultations(data?['patientId'] ?? '');

    setState(() { _consultations = list; _loading = false; });
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month-1]} ${dt.year}';
    } catch (_) { return iso.substring(0, 10); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Records'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await SessionManager.clearSession();
            if (mounted) Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
          }),
        ],
      ),
      drawer: Drawer(
        child: userData == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    (userData!['firstName'] ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 22,
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${userData!['firstName']} ${userData!['lastName']}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 17, fontWeight: FontWeight.bold)),
                Text('ID: ${userData!['patientId']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blue),
            title: Text('${userData!['city'] ?? ''}, '
                '${userData!['district'] ?? ''}, ${userData!['state'] ?? ''}'),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.blue),
            title: Text(userData!['WhatsApp_Number'] ?? 'No WhatsApp number'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await SessionManager.clearSession();
              if (mounted) Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
            },
          ),
        ]),
      ),
      body: Column(children: [
        // Welcome bar
        Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                (userData?['firstName'] ?? 'P')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hello, ${userData?['firstName'] ?? ''}!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Your consultation history',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            const Spacer(),
            Text('${_consultations.length} records',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ]),
        ),

        // Consultations list sorted by date (newest first)
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.blue))
              : _consultations.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.medical_information,
                size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No reports yet',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const Text('Your doctor will add reports after consultation',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ]))
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _consultations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = _consultations[i];
              final date = _formatDate(c['\$createdAt']);
              final diagnosis = c['diagnosis'] ?? '';

              return Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description,
                        color: Colors.blue),
                  ),
                  title: Text(
                        () {
                      try {
                        final opdRaw = c['opdReport'];
                        if (opdRaw != null && opdRaw.toString().isNotEmpty) {
                          final opd = jsonDecode(opdRaw);
                          final cc = opd['chief_complaint']?.toString() ?? '';
                          if (cc.isNotEmpty &&
                              cc != 'null' &&
                              !cc.toLowerCase().contains('not explicitly') &&
                              !cc.toLowerCase().contains('not stated') &&
                              cc.length > 3) {
                            return cc;
                          }
                        }
                      } catch (_) {}
                      return 'Consultation';
                    }(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),
                      Text(date,
                          style: const TextStyle(
                              color: Colors.blue, fontSize: 12)),
                      const SizedBox(height: 2),
                      Row(children: const [
                        Icon(Icons.description_outlined,
                            size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Report + Prescription available',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ]),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.blue),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultationDetailScreen(
                        consultation: c,
                        role: 'patient',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}



