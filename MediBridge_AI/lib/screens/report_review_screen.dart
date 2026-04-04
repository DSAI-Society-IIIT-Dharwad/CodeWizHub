import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/consultation_service.dart';
import 'doctor_dashboard_screen.dart';
import 'report_actions_screen.dart';

class ReportReviewScreen extends StatefulWidget {
  final String transcript;
  final Map<String, dynamic> opdReport;
  final Map<String, dynamic> prescription;
  final Map<String, dynamic> patient;
  final Map<String, dynamic> doctor;

  const ReportReviewScreen({
    super.key,
    required this.transcript,
    required this.opdReport,
    required this.prescription,
    required this.patient,
    required this.doctor,
  });

  @override
  State<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends State<ReportReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _saving = false;

  // OPD controllers
  late TextEditingController _chiefComplaintCtrl;
  late TextEditingController _symptomsCtrl;
  late TextEditingController _observationsCtrl;
  late TextEditingController _diagnosisCtrl;
  late TextEditingController _historyCtrl;
  late TextEditingController _adviceCtrl;
  late TextEditingController _followUpCtrl;

  // Prescription controllers
  late TextEditingController _prescNotesCtrl;
  List<Map<String, dynamic>> _medicines = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final o = widget.opdReport;
    final p = widget.prescription;

    _chiefComplaintCtrl = TextEditingController(text: o['chief_complaint'] ?? '');
    _symptomsCtrl = TextEditingController(text: (o['symptoms'] as List?)?.join(', ') ?? '');
    _observationsCtrl = TextEditingController(text: o['observations'] ?? '');
    _diagnosisCtrl = TextEditingController(text: o['diagnosis'] ?? '');
    _historyCtrl = TextEditingController(text: o['medical_history'] ?? '');
    _adviceCtrl = TextEditingController(text: o['advice'] ?? '');
    _followUpCtrl = TextEditingController(text: o['follow_up'] ?? '');
    _prescNotesCtrl = TextEditingController(text: p['additional_notes'] ?? '');

    final meds = p['medicines'];
    if (meds is List) {
      _medicines = List<Map<String, dynamic>>.from(meds.map((m) => Map<String, dynamic>.from(m)));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chiefComplaintCtrl.dispose();
    _symptomsCtrl.dispose();
    _observationsCtrl.dispose();
    _diagnosisCtrl.dispose();
    _historyCtrl.dispose();
    _adviceCtrl.dispose();
    _followUpCtrl.dispose();
    _prescNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitFinal() async {
    setState(() => _saving = true);

    final finalOpdReport = {
      ...widget.opdReport,
      'chief_complaint': _chiefComplaintCtrl.text.trim(),
      'symptoms': _symptomsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'observations': _observationsCtrl.text.trim(),
      'diagnosis': _diagnosisCtrl.text.trim(),
      'medical_history': _historyCtrl.text.trim(),
      'advice': _adviceCtrl.text.trim(),
      'follow_up': _followUpCtrl.text.trim(),
    };

    final finalPrescription = {
      ...widget.prescription,
      'medicines': _medicines,
      'additional_notes': _prescNotesCtrl.text.trim(),
    };

    final result = await ConsultationService().saveConsultation(
      doctorId: widget.doctor['doctorId'] ?? '',
      patientId: widget.patient['patientId'] ?? '',
      transcript: widget.transcript,
      opdReport: finalOpdReport,
      prescription: finalPrescription,
    );

    setState(() => _saving = false);

    if (result['success'] && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Consultation Saved!'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Patient: ${widget.patient['firstName']} ${widget.patient['lastName']}'),
            const SizedBox(height: 4),
            Text('Consultation ID: ${result['consultationId']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(
                      builder: (_) => ReportActionsScreen(
                        consultation: {
                          ...finalOpdReport,
                          'opdReport': jsonEncode(finalOpdReport),
                          'prescriptionText': jsonEncode(finalPrescription),
                          'prescription': jsonEncode(finalPrescription['medicines'] ?? []),
                          '\$createdAt': DateTime.now().toIso8601String(),
                        },
                        consultationDocId: result['docId'] ?? '',
                        patient: widget.patient,
                        doctor: widget.doctor,
                      ),
                    ));
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskAlerts = widget.opdReport['risk_alerts'] as List?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Edit Report'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'OPD Report'),
            Tab(icon: Icon(Icons.medication), text: 'Prescription'),
          ],
        ),
      ),
      body: Column(children: [
        // Patient bar
        Container(
          color: Colors.green.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.person, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text('${widget.patient['firstName']} ${widget.patient['lastName']} · ${widget.patient['patientId']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ),

        // Risk alerts banner
        if (riskAlerts != null && riskAlerts.isNotEmpty)
          Container(
            width: double.infinity,
            color: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Icon(Icons.warning, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Risk: ${riskAlerts.join(', ')}',
                  style: const TextStyle(color: Colors.red, fontSize: 13))),
            ]),
          ),

        // Tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // ── TAB 1: OPD REPORT ─────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Chief Complaint'),
                  _field(_chiefComplaintCtrl, 'Main reason for visit'),
                  _label('Symptoms (comma separated)'),
                  _field(_symptomsCtrl, 'e.g. fever, headache, cough'),
                  _label('Medical History'),
                  _field(_historyCtrl, 'Past medical history', maxLines: 2),
                  _label('Observations / Examination Notes'),
                  _field(_observationsCtrl, 'Clinical observations', maxLines: 3),
                  _label('Diagnosis'),
                  _field(_diagnosisCtrl, 'Primary diagnosis'),
                  _label('Advice for Patient'),
                  _field(_adviceCtrl, 'Lifestyle, diet advice', maxLines: 2),
                  _label('Follow Up'),
                  _field(_followUpCtrl, 'e.g. Return after 1 week'),
                  const SizedBox(height: 12),
                  // Transcript
                  ExpansionTile(
                    title: const Text('View Original Transcript', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey.shade100,
                        child: Text(widget.transcript, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ]),
              ),

              // ── TAB 2: PRESCRIPTION ───────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ..._medicines.asMap().entries.map((entry) {
                    final i = entry.key;
                    final m = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('💊 ${m['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => setState(() => _medicines.removeAt(i)),
                            ),
                          ]),
                          Text('Dosage: ${m['dosage'] ?? ''}'),
                          Text('Frequency: ${m['frequency'] ?? ''}'),
                          Text('Duration: ${m['duration'] ?? ''}'),
                          Text('Instructions: ${m['instructions'] ?? ''}'),
                        ]),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _showAddMedicineDialog,
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    label: const Text('Add Medicine', style: TextStyle(color: Colors.green)),
                  ),
                  const SizedBox(height: 12),
                  _label('Additional Notes for Patient'),
                  _field(_prescNotesCtrl, 'Any extra instructions', maxLines: 3),
                ]),
              ),
            ],
          ),
        ),

        // Submit button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saving ? null : _submitFinal,
              child: _saving
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Saving...', style: TextStyle(fontSize: 16)),
              ])
                  : const Text('✓ Confirm & Save Both Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 5),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
  );

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) => TextField(
    controller: c,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  void _showAddMedicineDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    final instrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Medicine'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Medicine Name *', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: dosageCtrl, decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: freqCtrl, decoration: const InputDecoration(labelText: 'Frequency (e.g. twice daily)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: durCtrl, decoration: const InputDecoration(labelText: 'Duration (e.g. 5 days)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: instrCtrl, decoration: const InputDecoration(labelText: 'Instructions (e.g. after food)', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() => _medicines.add({
                'name': nameCtrl.text.trim(),
                'dosage': dosageCtrl.text.trim(),
                'frequency': freqCtrl.text.trim(),
                'duration': durCtrl.text.trim(),
                'instructions': instrCtrl.text.trim(),
              }));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
