import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/session_manager.dart';
import '../services/consultation_service.dart';
import 'role_selection_screen.dart';
import 'consultation_detail_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});
  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> _allConsultations = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = false;
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await SessionManager.getSession();
    setState(() { userData = data; _loading = true; });

    final list = await ConsultationService().getStudentConsultations();
    setState(() {
      _allConsultations = list;
      _filtered = list;
      _loading = false;
    });
  }

  // AI semantic search
  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _filtered = _allConsultations);
      return;
    }

    setState(() => _searching = true);

    final results = await ConsultationService().semanticSearch(
      query: query,
      role: 'student',
    );

    setState(() {
      _filtered = results;
      _searching = false;
    });
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month-1]} ${dt.year}';
    } catch (_) { return ''; }
  }

  String _getChiefComplaint(Map<String, dynamic> c) {
    try {
      final raw = c['opdReport'];
      if (raw != null && raw.toString().isNotEmpty) {
        final opd = jsonDecode(raw);
        final cc = opd['chief_complaint']?.toString() ?? '';
        if (cc.isNotEmpty && cc != 'null') return cc;
      }
    } catch (_) {}
    return c['diagnosis']?.toString() ?? 'View report';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Studies'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SessionManager.clearSession();
              if (mounted) Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
            },
          ),
        ],
      ),
      body: Column(children: [

        // Student info bar
        Container(
          color: Colors.orange.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                (userData?['name'] ?? 'S')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userData?['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${userData?['college'] ?? ''} · ${userData?['course'] ?? ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_filtered.length} cases',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
        ),

        // AI Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by disease, symptom, diagnosis...',
              prefixIcon: _searching
                  ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.orange),
                  ))
                  : const Icon(Icons.search, color: Colors.orange),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  })
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (val) => _search(val),
          ),
        ),

        // Notice banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'All reports are anonymized. Patient details are hidden.',
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),

        // Reports list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : _filtered.isEmpty
              ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  _searchController.text.isNotEmpty
                      ? 'No results for "${_searchController.text}"'
                      : 'No case studies available yet',
                  style: const TextStyle(color: Colors.grey),
                ),
              ]))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = _filtered[i];
              final complaint = _getChiefComplaint(c);
              final date = _formatDate(c['\$createdAt']);

              // Anonymize patient data for students
              final anonymized = {
                ...c,
                'patientName': 'Anonymous Patient',
                'patientId': 'ANON-${(i + 1).toString().padLeft(3, '0')}',
              };

              return Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description,
                        color: Colors.orange),
                  ),
                  title: Text(
                    complaint,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),
                      Text(date,
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        c['diagnosis']?.toString() ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.orange),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultationDetailScreen(
                        consultation: anonymized,
                        role: 'student',
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
