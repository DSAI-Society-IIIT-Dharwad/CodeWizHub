import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/consultation_service.dart';
import '../appwrite_config.dart';
import 'doctor_dashboard_screen.dart';

class ReportActionsScreen extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final String consultationDocId;
  final Map<String, dynamic> patient;
  final Map<String, dynamic> doctor;

  const ReportActionsScreen({
    super.key,
    required this.consultation,
    required this.consultationDocId,
    required this.patient,
    required this.doctor,
  });

  @override
  State<ReportActionsScreen> createState() => _ReportActionsScreenState();
}

class _ReportActionsScreenState extends State<ReportActionsScreen> {
  final _whatsappController = TextEditingController();
  final _service = ConsultationService();

  bool _uploadingGovt = false;
  bool _uploadingStudents = false;
  bool _uploadingFiles = false;
  bool _govtDone = false;
  bool _studentsDone = false;

  final List<String> _attachedFileNames = [];
  final List<String> _attachedFilePaths = [];
  final List<String> _uploadedUrls = [];

  @override
  void initState() {
    super.initState();
    _whatsappController.text =
        widget.patient['WhatsApp_Number']?.toString() ?? '';

    print('=== ReportActionsScreen ===');
    print('consultationDocId: "${widget.consultationDocId}"');
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    super.dispose();
  }

  // ── UPLOAD TO GOVT ─────────────────────────────────────────────────────
  Future<void> _uploadToGovt() async {
    print('_uploadToGovt called, docId: "${widget.consultationDocId}"');

    if (widget.consultationDocId.isEmpty) {
      _showSnack('Error: No consultation ID found', Colors.red);
      return;
    }

    setState(() => _uploadingGovt = true);

    try {
      // ✅ Use AppwriteConfig.endpoint — NOT hardcoded URL
      final url =
          '${AppwriteConfig.endpoint}/databases/${AppwriteConfig.databaseId}/collections/${AppwriteConfig.consultationsCollection}/documents/${widget.consultationDocId}';

      print('PATCH URL: $url');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': AppwriteConfig.projectId,
          'X-Appwrite-Key': AppwriteConfig.apiKey, // ✅ Add API key
        },
        body: jsonEncode({
          'data': {'uploadedToGovt': true},
        }),
      );

      print('Govt response: ${response.statusCode} — ${response.body}');

      setState(() {
        _uploadingGovt = false;
        _govtDone = response.statusCode == 200;
      });

      _showSnack(
        response.statusCode == 200
            ? '✅ Uploaded to Government portal'
            : '❌ Failed: ${response.statusCode} — ${response.body}',
        response.statusCode == 200 ? Colors.green : Colors.red,
      );
    } catch (e) {
      setState(() => _uploadingGovt = false);
      _showSnack('❌ Error: $e', Colors.red);
    }
  }

  // ── UPLOAD TO STUDENTS ─────────────────────────────────────────────────
  Future<void> _uploadToStudents() async {
    print('_uploadToStudents called, docId: "${widget.consultationDocId}"');

    if (widget.consultationDocId.isEmpty) {
      _showSnack('Error: No consultation ID found', Colors.red);
      return;
    }

    setState(() => _uploadingStudents = true);

    try {
      final expiry = DateTime.now()
          .add(const Duration(days: 90))
          .toIso8601String();

      // ✅ Use AppwriteConfig.endpoint — NOT hardcoded URL
      final url =
          '${AppwriteConfig.endpoint}/databases/${AppwriteConfig.databaseId}/collections/${AppwriteConfig.consultationsCollection}/documents/${widget.consultationDocId}';

      print('PATCH URL: $url');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': AppwriteConfig.projectId,
          'X-Appwrite-Key': AppwriteConfig.apiKey, // ✅ Add API key
        },
        body: jsonEncode({
          'data': {
            'uploadedToStudents': true,
            'studentAccessExpiry': expiry,
          },
        }),
      );

      print('Students response: ${response.statusCode} — ${response.body}');

      setState(() {
        _uploadingStudents = false;
        _studentsDone = response.statusCode == 200;
      });

      _showSnack(
        response.statusCode == 200
            ? '✅ Uploaded for students (3-month access)'
            : '❌ Failed: ${response.statusCode} — ${response.body}',
        response.statusCode == 200 ? Colors.green : Colors.red,
      );
    } catch (e) {
      setState(() => _uploadingStudents = false);
      _showSnack('❌ Error: $e', Colors.red);
    }
  }

  // ── GENERATE OPD PDF ───────────────────────────────────────────────────
  Future<File> _generateOpdPdf() async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document();

    Map<String, dynamic> opd = {};
    try {
      final raw = widget.consultation['opdReport'];
      if (raw != null) opd = jsonDecode(raw);
    } catch (_) {}

    final date = _formatDate(widget.consultation['\$createdAt']);
    final patientName =
        '${widget.patient['firstName']} ${widget.patient['lastName']}';
    final patientId = widget.patient['patientId'] ?? '';
    final doctorName = widget.doctor['name'] ?? '';
    final doctorId = widget.doctor['doctorId'] ?? '';

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MediBridge AI — OPD Report',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.green900)),
                pw.SizedBox(height: 8),
                pw.Text('Patient: $patientName  ($patientId)',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('Doctor:  $doctorName  ($doctorId)',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('Date:    $date',
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _pdfRow(font, boldFont, 'Chief Complaint',
              opd['chief_complaint']?.toString() ?? ''),
          _pdfRow(font, boldFont, 'Symptoms',
              (opd['symptoms'] as List?)?.join(', ') ?? ''),
          _pdfRow(
              font,
              boldFont,
              'Diagnosis',
              opd['diagnosis']?.toString() ??
                  widget.consultation['diagnosis'] ??
                  ''),
          _pdfRow(font, boldFont, 'Observations',
              opd['observations']?.toString() ?? ''),
          _pdfRow(
              font, boldFont, 'Advice', opd['advice']?.toString() ?? ''),
          _pdfRow(font, boldFont, 'Follow Up',
              opd['follow_up']?.toString() ?? ''),
          pw.Spacer(),
          pw.Divider(),
          pw.Text('Generated by MediBridge AI · $date',
              style: pw.TextStyle(
                  font: font, fontSize: 9, color: PdfColors.grey)),
        ],
      ),
    ));

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/OPD_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── GENERATE PRESCRIPTION PDF ──────────────────────────────────────────
  Future<File> _generatePrescPdf() async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document();

    List meds = [];
    Map<String, dynamic> presc = {};
    try {
      final raw = widget.consultation['prescriptionText'];
      if (raw != null) {
        presc = jsonDecode(raw);
        meds = presc['medicines'] ?? [];
      }
    } catch (_) {}

    try {
      if (meds.isEmpty) {
        final raw = widget.consultation['prescription'];
        if (raw != null) {
          final decoded = jsonDecode(raw);
          if (decoded is List) meds = decoded;
        }
      }
    } catch (_) {}

    final date = _formatDate(widget.consultation['\$createdAt']);
    final patientName =
        '${widget.patient['firstName']} ${widget.patient['lastName']}';
    final patientId = widget.patient['patientId'] ?? '';
    final doctorName = widget.doctor['name'] ?? '';
    final doctorId = widget.doctor['doctorId'] ?? '';

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MediBridge AI — Prescription',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.blue900)),
                pw.SizedBox(height: 8),
                pw.Text('Patient: $patientName  ($patientId)',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('Doctor:  $doctorName  ($doctorId)',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.Text('Date:    $date',
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Medicines',
              style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                  color: PdfColors.blue900)),
          pw.SizedBox(height: 8),
          ...meds.asMap().entries.map((e) {
            final m = e.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${e.key + 1}. ${m['name'] ?? ''}',
                      style:
                      pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.Text(
                      'Dosage: ${m['dosage'] ?? ''}  Frequency: ${m['frequency'] ?? ''}  Duration: ${m['duration'] ?? ''}',
                      style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text(
                      'Instructions: ${m['instructions'] ?? ''}',
                      style: pw.TextStyle(font: font, fontSize: 11)),
                ],
              ),
            );
          }),
          if ((presc['additional_notes'] ?? '').toString().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Notes: ${presc['additional_notes']}',
                style: pw.TextStyle(font: font, fontSize: 12)),
          ],
          pw.Spacer(),
          pw.Divider(),
          pw.Text('Generated by MediBridge AI · $date',
              style: pw.TextStyle(
                  font: font, fontSize: 9, color: PdfColors.grey)),
        ],
      ),
    ));

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/Prescription_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _pdfRow(
      pw.Font font, pw.Font boldFont, String label, String value) {
    if (value.isEmpty) return pw.SizedBox();
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(font: font, fontSize: 12)),
        ],
      ),
    );
  }

  // ── WHATSAPP SHARE ─────────────────────────────────────────────────────
  Future<void> _shareViaWhatsApp() async {
    final phone = _whatsappController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Please enter WhatsApp number', Colors.red);
      return;
    }

    try {
      _showSnack('Generating PDFs...', Colors.blue);
      final opdFile = await _generateOpdPdf();
      final prescFile = await _generatePrescPdf();

      final patientName =
          '${widget.patient['firstName']} ${widget.patient['lastName']}';
      final date = _formatDate(widget.consultation['\$createdAt']);

      await Share.shareXFiles(
        [XFile(opdFile.path), XFile(prescFile.path)],
        text:
        'MediBridge AI Report\nPatient: $patientName\nDate: $date\n\nOPD report and prescription attached.',
      );
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    }
  }

  // ── ATTACH FILES ───────────────────────────────────────────────────────
  Future<void> _attachFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null) return;

    setState(() => _uploadingFiles = true);

    for (final file in result.files) {
      if (file.path != null) {
        _attachedFilePaths.add(file.path!);
        _attachedFileNames.add(file.name);
        final url =
        await _service.uploadAttachment(file.path!, file.name);
        if (url != null) _uploadedUrls.add(url);
      }
    }

    if (_uploadedUrls.isNotEmpty) {
      await _service.saveAttachments(
          widget.consultationDocId, _uploadedUrls);
    }

    setState(() => _uploadingFiles = false);
    _showSnack(
        '${result.files.length} file(s) attached', Colors.green);
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Actions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── SUCCESS BANNER ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Report Saved Successfully!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green)),
                        Text(
                          '${widget.patient['firstName']} ${widget.patient['lastName']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── ATTACH FILES ─────────────────────────────────────────────
              _sectionTitle('📎 Attach Additional Files', 'Optional'),
              const Text(
                'Attach blood reports, X-rays, CT scans or other documents.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              if (_attachedFileNames.isNotEmpty) ...[
                ..._attachedFileNames.map((name) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.attach_file,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(name,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                )),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  foregroundColor: Colors.green,
                ),
                icon: _uploadingFiles
                    ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.green))
                    : const Icon(Icons.upload_file),
                label: Text(_uploadingFiles
                    ? 'Uploading...'
                    : 'Attach Files (PDF / Image)'),
                onPressed: _uploadingFiles ? null : _attachFiles,
              ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),

              // ── WHATSAPP SHARE ───────────────────────────────────────────
              _sectionTitle(
                  '💬 Send Report via WhatsApp', 'Recommended'),
              const Text(
                'Share OPD report and prescription with the patient.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Patient WhatsApp Number',
                  hintText: 'e.g. 9876543210',
                  border: const OutlineInputBorder(),
                  prefixIcon:
                  const Icon(Icons.phone, color: Colors.green),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _whatsappController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Send Report via WhatsApp',
                      style: TextStyle(fontSize: 15)),
                  onPressed: _shareViaWhatsApp,
                ),
              ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),

              // ── UPLOAD OPTIONS ───────────────────────────────────────────
              _sectionTitle('📤 Upload Report', 'Choose one or both'),
              const SizedBox(height: 12),

              _uploadCard(
                icon: Icons.account_balance,
                iconColor: Colors.blue,
                title: 'Upload to Government Portal',
                subtitle:
                'Anonymized data for health analytics and monitoring.',
                buttonLabel: _govtDone
                    ? '✓ Uploaded to Government'
                    : 'Upload to Government',
                buttonColor:
                _govtDone ? Colors.grey : Colors.blue,
                loading: _uploadingGovt,
                done: _govtDone,
                onTap: _govtDone ? null : _uploadToGovt,
              ),

              const SizedBox(height: 12),

              _uploadCard(
                icon: Icons.menu_book,
                iconColor: Colors.orange,
                title: 'Upload for Medical Students',
                subtitle:
                'Anonymized report visible to students for 3 months only.',
                buttonLabel: _studentsDone
                    ? '✓ Uploaded for Students'
                    : 'Upload for Students',
                buttonColor:
                _studentsDone ? Colors.grey : Colors.orange,
                loading: _uploadingStudents,
                done: _studentsDone,
                onTap: _studentsDone ? null : _uploadToStudents,
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // ── DONE BUTTON ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const DoctorDashboardScreen()),
                  ),
                  child: const Text('Done — Back to Dashboard',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ]),
      ),
    );
  }

  Widget _sectionTitle(String title, String badge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(badge,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade800)),
        ),
      ]),
    );
  }

  Widget _uploadCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required bool loading,
    required bool done,
    required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: done
                ? Colors.grey.shade300
                : iconColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor:
                iconColor.withValues(alpha: 0.1),
                radius: 20,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onTap,
                child: loading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2))
                    : Text(buttonLabel),
              ),
            ),
          ]),
    );
  }
}
