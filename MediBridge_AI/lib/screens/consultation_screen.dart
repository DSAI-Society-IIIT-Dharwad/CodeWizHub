import 'package:flutter/material.dart';
import 'dart:convert'; // ✅ ADDED
import '../services/session_manager.dart';
import '../services/consultation_service.dart';
import 'role_selection_screen.dart';
import 'consultation_screen.dart';
import 'consultation_detail_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});
  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
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
    setState(() {
      userData = data;
      _loading = true;
    });

    final list = await ConsultationService()
        .getDoctorConsultations(data?['doctorId'] ?? '');

    List<Map<String, dynamic>> enriched = [];
    for (final c in list) {
      final patient = await ConsultationService()
          .getPatientById(c['patientId'] ?? '');

      // Check upload status from uploads collection
      final consultationId = c['consultationId']?.toString() ?? '';
      Map<String, bool> uploadStatus = {'govt': false, 'students': false};
      if (consultationId.isNotEmpty) {
        uploadStatus = await ConsultationService()
            .checkUploadStatus(consultationId);
      }

      enriched.add({
        ...c,
        'patientName': patient != null
            ? '${patient['firstName']} ${patient['lastName']}'
            : c['patientId'],
        'isGovtUploaded': uploadStatus['govt'] ?? false,      // ← NEW
        'isStudentsUploaded': uploadStatus['students'] ?? false, // ← NEW
      });
    }

    setState(() {
      _consultations = enriched;
      _loading = false;
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown date';
    try {
      final dt = DateTime.parse(isoDate);
      final months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return isoDate.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${userData?['name'] ?? ''}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SessionManager.clearSession();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text(
          'New Consultation',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConsultationScreen()),
        ).then((_) => _loadData()),
      ),

      body: Column(
        children: [
          // Doctor info bar
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 22,
                  child: Text(
                    (userData?['name'] ?? 'D')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData?['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      userData?['specialization'] ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_consultations.length} cases',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Header
          if (_consultations.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Recent Consultations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
                : _consultations.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 70, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    'No consultations yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const Text(
                    'Tap below to start a new consultation',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _consultations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = _consultations[i];
                final isGovt = c['isGovtUploaded'] == true;
                final isStudent = c['isStudentsUploaded'] == true;

                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Stack(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 8, 80, 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            (c['patientName'] ?? 'P')[0].toUpperCase(),
                            style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          c['patientName'] ?? 'Unknown Patient',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Text(
                                  () {
                                try {
                                  final raw = c['opdReport'];
                                  if (raw != null && raw.toString().isNotEmpty) {
                                    final opd = jsonDecode(raw);
                                    final cc = opd['chief_complaint']?.toString() ?? '';
                                    if (cc.isNotEmpty && cc != 'null') return cc;
                                  }
                                } catch (_) {}
                                return c['diagnosis']?.toString().isNotEmpty == true
                                    ? c['diagnosis']
                                    : 'Tap to view report';
                              }(),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDate(c['\$createdAt']),
                              style: const TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.green),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConsultationDetailScreen(
                              consultation: c,
                              role: 'doctor',
                            ),
                          ),
                        ),
                      ),

                      // ── STATUS ICONS (top-right) ─────────────────────────────────
                      Positioned(
                        top: 8,
                        right: 36,
                        child: Row(children: [
                          if (isStudent)
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    blurRadius: 4)],
                              ),
                              child: const Icon(Icons.menu_book,
                                  color: Colors.white, size: 12),
                            ),
                          if (isGovt)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 4)],
                              ),
                              child: const Icon(Icons.account_balance,
                                  color: Colors.white, size: 12),
                            ),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}




