import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import '../services/ai_service.dart';
import '../services/consultation_service.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final String role;

  const ConsultationDetailScreen({
    super.key,
    required this.consultation,
    required this.role,
  });

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Translation state
  String _selectedLanguage = 'English';
  bool _translating = false;
  String _translatedOpdBlock = '';
  final Map<String, String> _cache = {};

  // Upload state (doctor only)
  bool _uploadingGovt = false;
  bool _uploadingStudents = false;
  bool _govtDone = false;
  bool _studentsDone = false;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Kannada',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Marathi',
    'Bengali',
    'Gujarati',
  ];

  // ── PARSE OPD ──────────────────────────────────────────────────────────
  Map<String, dynamic> get _opd {
    try {
      final raw = widget.consultation['opdReport'];
      if (raw != null &&
          raw.toString().isNotEmpty &&
          raw.toString() != 'null') {
        final decoded = jsonDecode(raw.toString());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      print('opdReport parse error: $e');
    }
    return {};
  }

  // ── PARSE PRESCRIPTION HEADER ──────────────────────────────────────────
  Map<String, dynamic> get _presc {
    try {
      final raw = widget.consultation['prescriptionText'];
      if (raw != null &&
          raw.toString().isNotEmpty &&
          raw.toString() != 'null') {
        final decoded = jsonDecode(raw.toString());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      print('prescriptionText parse error: $e');
    }
    return {};
  }

  // ── PARSE MEDICINES ────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _medicines {
    try {
      final raw = widget.consultation['prescriptionText'];
      if (raw != null &&
          raw.toString().isNotEmpty &&
          raw.toString() != 'null') {
        final decoded = jsonDecode(raw.toString());
        if (decoded is Map && decoded['medicines'] is List) {
          return (decoded['medicines'] as List)
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    } catch (_) {}

    try {
      final raw = widget.consultation['prescription'];
      if (raw != null &&
          raw.toString().isNotEmpty &&
          raw.toString() != 'null') {
        final decoded = jsonDecode(raw.toString());
        if (decoded is List) {
          return decoded.map((m) => Map<String, dynamic>.from(m)).toList();
        }
        if (decoded is Map && decoded['medicines'] is List) {
          return (decoded['medicines'] as List)
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    } catch (_) {}

    return [];
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUploadStatus();
  }

  Future<void> _checkUploadStatus() async {
    final consultationId =
        widget.consultation['consultationId']?.toString() ?? '';
    if (consultationId.isEmpty) return;
    final status =
    await ConsultationService().checkUploadStatus(consultationId);
    if (mounted) {
      setState(() {
        _govtDone = status['govt'] ?? false;
        _studentsDone = status['students'] ?? false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── BUILD ENGLISH OPD TEXT BLOCK ───────────────────────────────────────
  String _buildEnglishOpdBlock() {
    final o = _opd;
    final symptoms = (o['symptoms'] as List?)?.join(', ') ??
        widget.consultation['symptoms'] ?? '';
    final diagnosis = o['diagnosis']?.toString() ??
        widget.consultation['diagnosis']?.toString() ?? '';
    final advice = o['advice']?.toString() ??
        widget.consultation['advice']?.toString() ?? '';
    final followUp = o['follow_up']?.toString() ??
        widget.consultation['followUp']?.toString() ?? '';

    return 'Chief Complaint:\n'
        '${o['chief_complaint'] ?? widget.consultation['chiefComplaint'] ?? ''}\n\n'
        'Symptoms:\n'
        '$symptoms\n\n'
        'Medical History:\n'
        '${o['medical_history'] ?? 'None'}\n\n'
        'Observations:\n'
        '${o['observations'] ?? ''}\n\n'
        'Diagnosis:\n'
        '$diagnosis\n\n'
        'Advice:\n'
        '$advice\n\n'
        'Follow Up:\n'
        '$followUp';
  }

  // ── TRANSLATE FULL OPD ─────────────────────────────────────────────────
  // Uses AIService.translateOpdBlock (Groq LLaMA primary, Gemini fallback).
  // Result is cached so each language is only fetched once.
  Future<void> _translateFullOPD(String language) async {
    // Update selected language immediately so dropdown reflects the choice
    if (mounted) setState(() => _selectedLanguage = language);

    if (language == 'English') {
      if (mounted) setState(() => _translatedOpdBlock = '');
      return;
    }

    // Serve from cache instantly — no API call needed
    if (_cache.containsKey(language)) {
      if (mounted) {
        setState(() {
          _translatedOpdBlock = _cache[language]!;
          _translating = false;
        });
      }
      return;
    }

    // Show spinner
    if (mounted) setState(() => _translating = true);

    try {
      final englishBlock = _buildEnglishOpdBlock();
      print('Starting translation to $language...');

      // Groq LLaMA handles the translation (no Gemini rate limits)
      final translated =
      await AIService().translateOpdBlock(englishBlock, language);

      print('Translation complete: ${translated.length} chars');

      // Cache and display — check mounted because this is async
      if (mounted) {
        _cache[language] = translated;
        setState(() {
          _translatedOpdBlock = translated;
          _translating = false;
        });
      }
    } catch (e) {
      print('Translation error: $e');
      if (mounted) {
        setState(() {
          // On error show English so screen is not empty
          _translatedOpdBlock = '';
          _translating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed. Showing English. ($e)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ── UPLOAD TO GOVT ─────────────────────────────────────────────────────
  Future<void> _uploadToGovt() async {
    final consultationId = widget.consultation['consultationId'];
    setState(() => _uploadingGovt = true);
    try {
      final result = await ConsultationService().createUploadRecord(
        consultationId: consultationId,
        uploadType: 'govt',
      );
      setState(() {
        _uploadingGovt = false;
        _govtDone = result['success'] == true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['success']
              ? '✅ Uploaded to Government'
              : '❌ ${result['error']}'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      setState(() => _uploadingGovt = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Upload error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  // ── UPLOAD TO STUDENTS ─────────────────────────────────────────────────
  Future<void> _uploadToStudents() async {
    final consultationId = widget.consultation['consultationId'];
    setState(() => _uploadingStudents = true);
    try {
      final result = await ConsultationService().createUploadRecord(
        consultationId: consultationId,
        uploadType: 'students',
      );
      setState(() {
        _uploadingStudents = false;
        _studentsDone = result['success'] == true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['success']
              ? '✅ Uploaded for Students'
              : '❌ ${result['error']}'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      setState(() => _uploadingStudents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Upload error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  // ── DOWNLOAD OPD PDF ───────────────────────────────────────────────────
  // Single flat function — no nested function inside.
  Future<void> _downloadOpdPdf() async {
    // If a non-English language is selected but not yet translated, translate first
    if (_selectedLanguage != 'English' && _translatedOpdBlock.isEmpty) {
      await _translateFullOPD(_selectedLanguage);
    }

    // Decide which content to put in the PDF
    final pdfContent =
    (_selectedLanguage != 'English' && _translatedOpdBlock.isNotEmpty)
        ? _translatedOpdBlock
        : _buildEnglishOpdBlock();

    try {
      setState(() => _translating = true);

      final o = _opd;
      final date = _formatDate(widget.consultation['\$createdAt']);
      final patientName = o['patient_name']?.toString() ??
          widget.consultation['patientName']?.toString() ?? '';
      final patientId = o['patient_id']?.toString() ??
          widget.consultation['patientId']?.toString() ?? '';
      final doctorName = o['doctor_name']?.toString() ?? '';
      final doctorId = o['doctor_id']?.toString() ??
          widget.consultation['doctorId']?.toString() ?? '';

      pw.Font font;
      pw.Font boldFont;
      try {
        switch (_selectedLanguage) {
          case 'Hindi':
          case 'Marathi':
            font = await PdfGoogleFonts.notoSansDevanagariRegular();
            boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
            break;
          case 'Kannada':
            font = await PdfGoogleFonts.notoSansKannadaRegular();
            boldFont = await PdfGoogleFonts.notoSansKannadaSemiBold();
            break;
          case 'Tamil':
            font = await PdfGoogleFonts.notoSansTamilRegular();
            boldFont = await PdfGoogleFonts.notoSansTamilSemiBold();
            break;
          case 'Telugu':
            font = await PdfGoogleFonts.notoSansTeluguRegular();
            boldFont = await PdfGoogleFonts.notoSansTeluguSemiBold();
            break;
          case 'Malayalam':
            font = await PdfGoogleFonts.notoSansMalayalamRegular();
            boldFont = await PdfGoogleFonts.notoSansMalayalamSemiBold();
            break;
          case 'Bengali':
            font = await PdfGoogleFonts.notoSansBengaliRegular();
            boldFont = await PdfGoogleFonts.notoSansBengaliSemiBold();
            break;
          case 'Gujarati':
            font = await PdfGoogleFonts.notoSansGujaratiRegular();
            boldFont = await PdfGoogleFonts.notoSansGujaratiSemiBold();
            break;
          default:
            font = await PdfGoogleFonts.notoSansRegular();
            boldFont = await PdfGoogleFonts.notoSansBold();
        }
      } catch (_) {
        font = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
      }

      final pdf = pw.Document();
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
                  pw.SizedBox(height: 10),
                  pw.Text('Patient: $patientName  ($patientId)',
                      style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 3),
                  pw.Text('Doctor:  $doctorName  ($doctorId)',
                      style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 3),
                  pw.Text('Date:    $date',
                      style: pw.TextStyle(font: font, fontSize: 12)),
                  if (_selectedLanguage != 'English') ...[
                    pw.SizedBox(height: 3),
                    pw.Text('Language: $_selectedLanguage',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 11,
                            color: PdfColors.green800)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(pdfContent,
                style:
                pw.TextStyle(font: font, fontSize: 12, lineSpacing: 6)),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Text('Generated by MediBridge AI · $date',
                style: pw.TextStyle(
                    font: font, fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ));

      await _savePdfAndShare(pdf, 'OPD_Report');
      if (mounted) setState(() => _translating = false);
    } catch (e) {
      if (mounted) setState(() => _translating = false);
      _showError('PDF error: $e');
    }
  }

  // ── DOWNLOAD PRESCRIPTION PDF ──────────────────────────────────────────
  Future<void> _downloadPrescPdf() async {
    try {
      setState(() => _translating = true);
      final p = _presc;
      final meds = _medicines;
      final date = _formatDate(widget.consultation['\$createdAt']);
      final patientName = p['patient_name']?.toString() ??
          widget.consultation['patientName']?.toString() ?? '';
      final patientId = widget.consultation['patientId']?.toString() ?? '';
      final doctorName = p['doctor_name']?.toString() ?? '';
      final doctorId = widget.consultation['doctorId']?.toString() ?? '';

      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      final pdf = pw.Document();
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
                  pw.SizedBox(height: 10),
                  pw.Text('Patient: $patientName  ($patientId)',
                      style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 3),
                  pw.Text('Doctor:  $doctorName  ($doctorId)',
                      style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 3),
                  pw.Text('Date:    $date',
                      style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Medicines',
                style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 14,
                    color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            if (meds.isEmpty)
              pw.Text('No medicines recorded.',
                  style: pw.TextStyle(font: font, fontSize: 12))
            else
              ...meds.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${i + 1}. ${m['name'] ?? ''}',
                          style:
                          pw.TextStyle(font: boldFont, fontSize: 13)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          'Dosage: ${m['dosage'] ?? ''}   Frequency: ${m['frequency'] ?? ''}',
                          style: pw.TextStyle(font: font, fontSize: 11)),
                      pw.Text(
                          'Duration: ${m['duration'] ?? ''}   Instructions: ${m['instructions'] ?? ''}',
                          style: pw.TextStyle(font: font, fontSize: 11)),
                    ],
                  ),
                );
              }),
            if ((p['additional_notes'] ?? '').toString().isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('Additional Notes:',
                  style: pw.TextStyle(font: boldFont, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text(p['additional_notes'].toString(),
                  style: pw.TextStyle(font: font, fontSize: 12)),
            ],
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Text('Generated by MediBridge AI · $date',
                style: pw.TextStyle(
                    font: font, fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ));

      await _savePdfAndShare(pdf, 'Prescription');
      if (mounted) setState(() => _translating = false);
    } catch (e) {
      if (mounted) setState(() => _translating = false);
      _showError('Prescription PDF error: $e');
    }
  }

  Future<void> _savePdfAndShare(pw.Document pdf, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/${name}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$name - MediBridge AI',
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _opd;
    final p = _presc;
    final meds = _medicines;
    final isPatient = widget.role == 'patient';
    final isDoctor = widget.role == 'doctor';
    final date = _formatDate(widget.consultation['\$createdAt']);

    final patientName = o['patient_name']?.toString() ??
        widget.consultation['patientName']?.toString() ?? '';
    final patientId = o['patient_id']?.toString() ??
        widget.consultation['patientId']?.toString() ?? '';
    final doctorName = o['doctor_name']?.toString() ?? '';
    final doctorId = o['doctor_id']?.toString() ??
        widget.consultation['doctorId']?.toString() ?? '';

    final showTranslated =
        _selectedLanguage != 'English' &&
            _translatedOpdBlock.isNotEmpty &&
            !_translating;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPatient
            ? 'My Report'
            : isDoctor
            ? 'Consultation Details'
            : 'Case Study'),
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
        // ── SHARED HEADER ───────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.green.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(Icons.person, 'Patient', '$patientName  ($patientId)'),
              const SizedBox(height: 4),
              _headerRow(
                  Icons.medical_services, 'Doctor', '$doctorName  ($doctorId)'),
              const SizedBox(height: 4),
              _headerRow(Icons.calendar_today, 'Date', date),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // ── TAB 1: OPD REPORT ────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language selector — patient only
                    if (isPatient) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(children: [
                          const Icon(Icons.translate,
                              color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          const Text('Language:',
                              style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              isExpanded: true,
                              underline: const SizedBox(),
                              isDense: true,
                              items: _languages
                                  .map((l) => DropdownMenuItem(
                                  value: l, child: Text(l)))
                                  .toList(),
                              onChanged: _translating
                                  ? null
                                  : (val) {
                                if (val != null) {
                                  _translateFullOPD(val);
                                }
                              },
                            ),
                          ),
                          if (_translating) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.blue),
                            ),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Download OPD PDF button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Download OPD PDF'),
                        onPressed: _translating ? null : _downloadOpdPdf,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Loading / translated / English structured view
                    if (_translating)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(children: [
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(height: 10),
                            Text('Translating...',
                                style: TextStyle(color: Colors.grey)),
                          ]),
                        ),
                      )
                    else if (showTranslated)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _translatedOpdBlock,
                          style:
                          const TextStyle(fontSize: 14, height: 1.7),
                        ),
                      )
                    else ...[
                        _opdField(
                            '🩺 Chief Complaint',
                            o['chief_complaint']?.toString() ??
                                widget.consultation['chiefComplaint']
                                    ?.toString()),
                        _opdField(
                            '🧾 Symptoms',
                            (o['symptoms'] as List?)?.join(', ') ??
                                widget.consultation['symptoms']?.toString()),
                        _opdField('📋 Medical History',
                            o['medical_history']?.toString()),
                        _opdField(
                            '🔬 Observations', o['observations']?.toString()),
                        _opdField(
                            '🧠 Diagnosis',
                            o['diagnosis']?.toString() ??
                                widget.consultation['diagnosis']?.toString(),
                            highlight: true),
                        _opdField(
                            '💊 Advice',
                            o['advice']?.toString() ??
                                widget.consultation['advice']?.toString()),
                        _opdField(
                            '📅 Follow Up',
                            o['follow_up']?.toString() ??
                                widget.consultation['followUp']?.toString()),
                      ],

                    // Transcript — doctor only
                    if (isDoctor) ...[
                      const SizedBox(height: 10),
                      ExpansionTile(
                        title: const Text('View Original Transcript',
                            style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            color: Colors.grey.shade100,
                            child: Text(
                              widget.consultation['transcript']
                                  ?.toString() ??
                                  '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Upload options — doctor only
                    if (isDoctor) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('📤 Upload Report',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text(
                          'Upload to government portal or share with medical students.',
                          style:
                          TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      _uploadOptionCard(
                        icon: Icons.account_balance,
                        iconColor: Colors.blue,
                        title: 'Upload to Government Portal',
                        subtitle: 'Anonymized data for health analytics.',
                        buttonLabel: _govtDone
                            ? '✓ Already Uploaded to Government'
                            : 'Upload to Government',
                        buttonColor: _govtDone ? Colors.grey : Colors.blue,
                        loading: _uploadingGovt,
                        done: _govtDone,
                        onTap: _govtDone ? null : _uploadToGovt,
                      ),
                      const SizedBox(height: 10),
                      _uploadOptionCard(
                        icon: Icons.menu_book,
                        iconColor: Colors.orange,
                        title: 'Upload for Medical Students',
                        subtitle: 'Visible to students for 3 months only.',
                        buttonLabel: _studentsDone
                            ? '✓ Already Uploaded for Students'
                            : 'Upload for Students',
                        buttonColor:
                        _studentsDone ? Colors.grey : Colors.orange,
                        loading: _uploadingStudents,
                        done: _studentsDone,
                        onTap: _studentsDone ? null : _uploadToStudents,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),

              // ── TAB 2: PRESCRIPTION ──────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Download Prescription PDF'),
                        onPressed: _downloadPrescPdf,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Medicines',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    if (meds.isEmpty)
                      const Text('No medicines recorded.',
                          style: TextStyle(color: Colors.grey))
                    else
                      ...meds.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. 💊 ${m['name'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                _prescRow('Dosage', m['dosage']?.toString()),
                                _prescRow(
                                    'Frequency', m['frequency']?.toString()),
                                _prescRow(
                                    'Duration', m['duration']?.toString()),
                                _prescRow('Instructions',
                                    m['instructions']?.toString()),
                              ],
                            ),
                          ),
                        );
                      }),
                    if ((p['additional_notes'] ?? '')
                        .toString()
                        .isNotEmpty &&
                        p['additional_notes'].toString() != 'null') ...[
                      const SizedBox(height: 8),
                      _opdField('📝 Additional Notes',
                          p['additional_notes'].toString()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── UI HELPERS ─────────────────────────────────────────────────────────
  Widget _headerRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 15, color: Colors.green.shade700),
      const SizedBox(width: 6),
      Text('$label: ',
          style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600)),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _opdField(String label, String? value, {bool highlight = false}) {
    if (value == null ||
        value.isEmpty ||
        value == 'null' ||
        value == '[]') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
            highlight ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: highlight
                    ? Colors.green.shade300
                    : Colors.grey.shade200),
          ),
          child: Text(value,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: highlight
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: highlight
                      ? Colors.green.shade900
                      : Colors.black87)),
        ),
      ]),
    );
  }

  Widget _prescRow(String label, String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 95,
            child: Text('$label: ',
                style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _uploadOptionCard({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
          done ? Colors.grey.shade300 : iconColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              radius: 18,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            if (done)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onTap,
              child: loading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text(buttonLabel,
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import '../services/ai_service.dart';
import '../services/consultation_service.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final String role;

  const ConsultationDetailScreen({
    super.key,
    required this.consultation,
    required this.role,
  });

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Translation state
  String _selectedLanguage = 'English';
  bool _translating = false;
  String _translatedOpdBlock = '';
  final Map<String, String> _cache = {};

  // Upload state (doctor only)
  bool _uploadingGovt = false;
  bool _uploadingStudents = false;
  bool _govtDone = false;
  bool _studentsDone = false;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Kannada',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Marathi',
    'Bengali',
    'Gujarati',
  ];

  // ── PARSE OPD ──────────────────────────────────────────────────────────
  Map<String, dynamic> get _opd {
    try {
      final raw = widget.consultation['opdReport'];
      if (raw != null &&
          raw.toString().isNotEmpty &&
          raw.toString() != 'null') {
        final decoded = jsonDecode(raw.toString());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      print('opdReport parse error: $e');
    }
    return {};
  }

  // ── PARSE PRESCRIPTION HEADER ──────────────────────────────────────────
  Map<String, dynamic> get _presc {
    try {
      final raw = widget.consultation['prescriptionText'];
      if (raw != null &&
          raw.toString().isNotEmpty &&
          raw.toString() != 'null') {
        final decoded = jsonDecode(raw.toString());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      print('prescriptionText parse error: $e');
    }
    return {};
  }

  // ── PARSE MEDICINES ────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _medicines {
    try {
      final raw = widget.consultation['prescriptionText'];
      if (raw != null &&
          raw.toString().isNotEmpty &&
          raw.toString() != 'null') {
        final decoded = jsonDecode(raw.toString());
        if (decoded is Map && decoded['medicines'] is List) {
          return (decoded['medicines'] as List)
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    } catch (_) {}

    try {
      final raw = widget.consultation['prescription'];
      if (raw != null &&
          raw.toString().isNotEmpty &&
          raw.toString() != 'null') {
        final decoded = jsonDecode(raw.toString());
        if (decoded is List) {
          return decoded.map((m) => Map<String, dynamic>.from(m)).toList();
        }
        if (decoded is Map && decoded['medicines'] is List) {
          return (decoded['medicines'] as List)
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      }
    } catch (_) {}

    return [];
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUploadStatus();
  }

  Future<void> _checkUploadStatus() async {
    final consultationId =
        widget.consultation['consultationId']?.toString() ?? '';
    if (consultationId.isEmpty) return;
    final status =
    await ConsultationService().checkUploadStatus(consultationId);
    if (mounted) {
      setState(() {
        _govtDone = status['govt'] ?? false;
        _studentsDone = status['students'] ?? false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── BUILD ENGLISH OPD TEXT BLOCK ───────────────────────────────────────
  String _buildEnglishOpdBlock() {
    final o = _opd;
    final symptoms = (o['symptoms'] as List?)?.join(', ') ??
        widget.consultation['symptoms'] ?? '';
    final diagnosis = o['diagnosis']?.toString() ??
        widget.consultation['diagnosis']?.toString() ?? '';
    final advice = o['advice']?.toString() ??
        widget.consultation['advice']?.toString() ?? '';
    final followUp = o['follow_up']?.toString() ??
        widget.consultation['followUp']?.toString() ?? '';

    return 'Chief Complaint:\n'
        '${o['chief_complaint'] ?? widget.consultation['chiefComplaint'] ?? ''}\n\n'
        'Symptoms:\n'
        '$symptoms\n\n'
        'Medical History:\n'
        '${o['medical_history'] ?? 'None'}\n\n'
        'Observations:\n'
        '${o['observations'] ?? ''}\n\n'
        'Diagnosis:\n'
        '$diagnosis\n\n'
        'Advice:\n'
        '$advice\n\n'
        'Follow Up:\n'
        '$followUp';
  }

  // ── TRANSLATE FULL OPD ─────────────────────────────────────────────────
  // Uses AIService.translateOpdBlock (Groq LLaMA primary, Gemini fallback).
  // Result is cached so each language is only fetched once.
  Future<void> _translateFullOPD(String language) async {
    // Update selected language immediately so dropdown reflects the choice
    if (mounted) setState(() => _selectedLanguage = language);

    if (language == 'English') {
      if (mounted) setState(() => _translatedOpdBlock = '');
      return;
    }

    // Serve from cache instantly — no API call needed
    if (_cache.containsKey(language)) {
      if (mounted) {
        setState(() {
          _translatedOpdBlock = _cache[language]!;
          _translating = false;
        });
      }
      return;
    }

    // Show spinner
    if (mounted) setState(() => _translating = true);

    try {
      final englishBlock = _buildEnglishOpdBlock();
      print('Starting translation to $language...');

      // Groq LLaMA handles the translation (no Gemini rate limits)
      final translated =
      await AIService().translateOpdBlock(englishBlock, language);

      print('Translation complete: ${translated.length} chars');

      // Cache and display — check mounted because this is async
      if (mounted) {
        _cache[language] = translated;
        setState(() {
          _translatedOpdBlock = translated;
          _translating = false;
        });
      }
    } catch (e) {
      print('Translation error: $e');
      if (mounted) {
        setState(() {
          // On error show English so screen is not empty
          _translatedOpdBlock = '';
          _translating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed. Showing English. ($e)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ── UPLOAD TO GOVT ─────────────────────────────────────────────────────
  Future<void> _uploadToGovt() async {
    final consultationId = widget.consultation['consultationId'];
    setState(() => _uploadingGovt = true);
    try {
      final result = await ConsultationService().createUploadRecord(
        consultationId: consultationId,
        uploadType: 'govt',
      );
      setState(() {
        _uploadingGovt = false;
        _govtDone = result['success'] == true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['success']
              ? '✅ Uploaded to Government'
              : '❌ ${result['error']}'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      setState(() => _uploadingGovt = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Upload error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  // ── UPLOAD TO STUDENTS ─────────────────────────────────────────────────
  Future<void> _uploadToStudents() async {
    final consultationId = widget.consultation['consultationId'];
    setState(() => _uploadingStudents = true);
    try {
      final result = await ConsultationService().createUploadRecord(
        consultationId: consultationId,
        uploadType: 'students',
      );
      setState(() {
        _uploadingStudents = false;
        _studentsDone = result['success'] == true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['success']
              ? '✅ Uploaded for Students'
              : '❌ ${result['error']}'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      setState(() => _uploadingStudents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Upload error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  // ── DOWNLOAD OPD PDF ───────────────────────────────────────────────────
  // Single flat function — no nested function inside.
  Future<void> _downloadOpdPdf() async {
    // If a non-English language is selected but not yet translated, translate first
    if (_selectedLanguage != 'English' && _translatedOpdBlock.isEmpty) {
      await _translateFullOPD(_selectedLanguage);
    }

    // Decide which content to put in the PDF
    final pdfContent =
    (_selectedLanguage != 'English' && _translatedOpdBlock.isNotEmpty)
        ? _translatedOpdBlock
        : _buildEnglishOpdBlock();

    try {
      setState(() => _translating = true);

      final o = _opd;
      final date = _formatDate(widget.consultation['\$createdAt']);
      final patientName = o['patient_name']?.toString() ??
          widget.consultation['patientName']?.toString() ?? '';
      final patientId = o['patient_id']?.toString() ??
          widget.consultation['patientId']?.toString() ?? '';
      final doctorName = o['doctor_name']?.toString() ?? '';
      final doctorId = o['doctor_id']?.toString() ??
          widget.consultation['doctorId']?.toString() ?? '';

      pw.Font font;
      pw.Font boldFont;
      try {
        switch (_selectedLanguage) {
          case 'Hindi':
          case 'Marathi':
            font = await PdfGoogleFonts.notoSansDevanagariRegular();
            boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
            break;
          case 'Kannada':
            font = await PdfGoogleFonts.notoSansKannadaRegular();
            boldFont = await PdfGoogleFonts.notoSansKannadaSemiBold();
            break;
          case 'Tamil':
            font = await PdfGoogleFonts.notoSansTamilRegular();
            boldFont = await PdfGoogleFonts.notoSansTamilSemiBold();
            break;
          case 'Telugu':
            font = await PdfGoogleFonts.notoSansTeluguRegular();
            boldFont = await PdfGoogleFonts.notoSansTeluguSemiBold();
            break;
          case 'Malayalam':
            font = await PdfGoogleFonts.notoSansMalayalamRegular();
            boldFont = await PdfGoogleFonts.notoSansMalayalamSemiBold();
            break;
          case 'Bengali':
            font = await PdfGoogleFonts.notoSansBengaliRegular();
            boldFont = await PdfGoogleFonts.notoSansBengaliSemiBold();
            break;
          case 'Gujarati':
            font = await PdfGoogleFonts.notoSansGujaratiRegular();
            boldFont = await PdfGoogleFonts.notoSansGujaratiSemiBold();
            break;
          default:
            font = await PdfGoogleFonts.notoSansRegular();
            boldFont = await PdfGoogleFonts.notoSansBold();
        }
      } catch (_) {
        font = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
      }

      final pdf = pw.Document();
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
                  pw.SizedBox(height: 10),
                  pw.Text('Patient: $patientName  ($patientId)',
                      style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 3),
                  pw.Text('Doctor:  $doctorName  ($doctorId)',
                      style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 3),
                  pw.Text('Date:    $date',
                      style: pw.TextStyle(font: font, fontSize: 12)),
                  if (_selectedLanguage != 'English') ...[
                    pw.SizedBox(height: 3),
                    pw.Text('Language: $_selectedLanguage',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 11,
                            color: PdfColors.green800)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(pdfContent,
                style:
                pw.TextStyle(font: font, fontSize: 12, lineSpacing: 6)),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Text('Generated by MediBridge AI · $date',
                style: pw.TextStyle(
                    font: font, fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ));

      await _savePdfAndShare(pdf, 'OPD_Report');
      if (mounted) setState(() => _translating = false);
    } catch (e) {
      if (mounted) setState(() => _translating = false);
      _showError('PDF error: $e');
    }
  }

  // ── DOWNLOAD PRESCRIPTION PDF ──────────────────────────────────────────
  Future<void> _downloadPrescPdf() async {
    try {
      setState(() => _translating = true);
      final p = _presc;
      final meds = _medicines;
      final date = _formatDate(widget.consultation['\$createdAt']);
      final patientName = p['patient_name']?.toString() ??
          widget.consultation['patientName']?.toString() ?? '';
      final patientId = widget.consultation['patientId']?.toString() ?? '';
      final doctorName = p['doctor_name']?.toString() ?? '';
      final doctorId = widget.consultation['doctorId']?.toString() ?? '';

      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      final pdf = pw.Document();
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
                  pw.SizedBox(height: 10),
                  pw.Text('Patient: $patientName  ($patientId)',
                      style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 3),
                  pw.Text('Doctor:  $doctorName  ($doctorId)',
                      style: pw.TextStyle(font: boldFont, fontSize: 12)),
                  pw.SizedBox(height: 3),
                  pw.Text('Date:    $date',
                      style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Medicines',
                style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 14,
                    color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            if (meds.isEmpty)
              pw.Text('No medicines recorded.',
                  style: pw.TextStyle(font: font, fontSize: 12))
            else
              ...meds.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${i + 1}. ${m['name'] ?? ''}',
                          style:
                          pw.TextStyle(font: boldFont, fontSize: 13)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          'Dosage: ${m['dosage'] ?? ''}   Frequency: ${m['frequency'] ?? ''}',
                          style: pw.TextStyle(font: font, fontSize: 11)),
                      pw.Text(
                          'Duration: ${m['duration'] ?? ''}   Instructions: ${m['instructions'] ?? ''}',
                          style: pw.TextStyle(font: font, fontSize: 11)),
                    ],
                  ),
                );
              }),
            if ((p['additional_notes'] ?? '').toString().isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('Additional Notes:',
                  style: pw.TextStyle(font: boldFont, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text(p['additional_notes'].toString(),
                  style: pw.TextStyle(font: font, fontSize: 12)),
            ],
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Text('Generated by MediBridge AI · $date',
                style: pw.TextStyle(
                    font: font, fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ));

      await _savePdfAndShare(pdf, 'Prescription');
      if (mounted) setState(() => _translating = false);
    } catch (e) {
      if (mounted) setState(() => _translating = false);
      _showError('Prescription PDF error: $e');
    }
  }

  Future<void> _savePdfAndShare(pw.Document pdf, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/${name}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$name - MediBridge AI',
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _opd;
    final p = _presc;
    final meds = _medicines;
    final isPatient = widget.role == 'patient';
    final isDoctor = widget.role == 'doctor';
    final date = _formatDate(widget.consultation['\$createdAt']);

    final patientName = o['patient_name']?.toString() ??
        widget.consultation['patientName']?.toString() ?? '';
    final patientId = o['patient_id']?.toString() ??
        widget.consultation['patientId']?.toString() ?? '';
    final doctorName = o['doctor_name']?.toString() ?? '';
    final doctorId = o['doctor_id']?.toString() ??
        widget.consultation['doctorId']?.toString() ?? '';

    final showTranslated =
        _selectedLanguage != 'English' &&
            _translatedOpdBlock.isNotEmpty &&
            !_translating;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPatient
            ? 'My Report'
            : isDoctor
            ? 'Consultation Details'
            : 'Case Study'),
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
        // ── SHARED HEADER ───────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.green.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(Icons.person, 'Patient', '$patientName  ($patientId)'),
              const SizedBox(height: 4),
              _headerRow(
                  Icons.medical_services, 'Doctor', '$doctorName  ($doctorId)'),
              const SizedBox(height: 4),
              _headerRow(Icons.calendar_today, 'Date', date),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // ── TAB 1: OPD REPORT ────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language selector — patient only
                    if (isPatient) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(children: [
                          const Icon(Icons.translate,
                              color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          const Text('Language:',
                              style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              isExpanded: true,
                              underline: const SizedBox(),
                              isDense: true,
                              items: _languages
                                  .map((l) => DropdownMenuItem(
                                  value: l, child: Text(l)))
                                  .toList(),
                              onChanged: _translating
                                  ? null
                                  : (val) {
                                if (val != null) {
                                  _translateFullOPD(val);
                                }
                              },
                            ),
                          ),
                          if (_translating) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.blue),
                            ),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Download OPD PDF button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Download OPD PDF'),
                        onPressed: _translating ? null : _downloadOpdPdf,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Loading / translated / English structured view
                    if (_translating)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(children: [
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(height: 10),
                            Text('Translating...',
                                style: TextStyle(color: Colors.grey)),
                          ]),
                        ),
                      )
                    else if (showTranslated)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _translatedOpdBlock,
                          style:
                          const TextStyle(fontSize: 14, height: 1.7),
                        ),
                      )
                    else ...[
                        _opdField(
                            '🩺 Chief Complaint',
                            o['chief_complaint']?.toString() ??
                                widget.consultation['chiefComplaint']
                                    ?.toString()),
                        _opdField(
                            '🧾 Symptoms',
                            (o['symptoms'] as List?)?.join(', ') ??
                                widget.consultation['symptoms']?.toString()),
                        _opdField('📋 Medical History',
                            o['medical_history']?.toString()),
                        _opdField(
                            '🔬 Observations', o['observations']?.toString()),
                        _opdField(
                            '🧠 Diagnosis',
                            o['diagnosis']?.toString() ??
                                widget.consultation['diagnosis']?.toString(),
                            highlight: true),
                        _opdField(
                            '💊 Advice',
                            o['advice']?.toString() ??
                                widget.consultation['advice']?.toString()),
                        _opdField(
                            '📅 Follow Up',
                            o['follow_up']?.toString() ??
                                widget.consultation['followUp']?.toString()),
                      ],

                    // Transcript — doctor only
                    if (isDoctor) ...[
                      const SizedBox(height: 10),
                      ExpansionTile(
                        title: const Text('View Original Transcript',
                            style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            color: Colors.grey.shade100,
                            child: Text(
                              widget.consultation['transcript']
                                  ?.toString() ??
                                  '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Upload options — doctor only
                    if (isDoctor) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('📤 Upload Report',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text(
                          'Upload to government portal or share with medical students.',
                          style:
                          TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      _uploadOptionCard(
                        icon: Icons.account_balance,
                        iconColor: Colors.blue,
                        title: 'Upload to Government Portal',
                        subtitle: 'Anonymized data for health analytics.',
                        buttonLabel: _govtDone
                            ? '✓ Already Uploaded to Government'
                            : 'Upload to Government',
                        buttonColor: _govtDone ? Colors.grey : Colors.blue,
                        loading: _uploadingGovt,
                        done: _govtDone,
                        onTap: _govtDone ? null : _uploadToGovt,
                      ),
                      const SizedBox(height: 10),
                      _uploadOptionCard(
                        icon: Icons.menu_book,
                        iconColor: Colors.orange,
                        title: 'Upload for Medical Students',
                        subtitle: 'Visible to students for 3 months only.',
                        buttonLabel: _studentsDone
                            ? '✓ Already Uploaded for Students'
                            : 'Upload for Students',
                        buttonColor:
                        _studentsDone ? Colors.grey : Colors.orange,
                        loading: _uploadingStudents,
                        done: _studentsDone,
                        onTap: _studentsDone ? null : _uploadToStudents,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),

              // ── TAB 2: PRESCRIPTION ──────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Download Prescription PDF'),
                        onPressed: _downloadPrescPdf,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Medicines',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    if (meds.isEmpty)
                      const Text('No medicines recorded.',
                          style: TextStyle(color: Colors.grey))
                    else
                      ...meds.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. 💊 ${m['name'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                _prescRow('Dosage', m['dosage']?.toString()),
                                _prescRow(
                                    'Frequency', m['frequency']?.toString()),
                                _prescRow(
                                    'Duration', m['duration']?.toString()),
                                _prescRow('Instructions',
                                    m['instructions']?.toString()),
                              ],
                            ),
                          ),
                        );
                      }),
                    if ((p['additional_notes'] ?? '')
                        .toString()
                        .isNotEmpty &&
                        p['additional_notes'].toString() != 'null') ...[
                      const SizedBox(height: 8),
                      _opdField('📝 Additional Notes',
                          p['additional_notes'].toString()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── UI HELPERS ─────────────────────────────────────────────────────────
  Widget _headerRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 15, color: Colors.green.shade700),
      const SizedBox(width: 6),
      Text('$label: ',
          style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600)),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _opdField(String label, String? value, {bool highlight = false}) {
    if (value == null ||
        value.isEmpty ||
        value == 'null' ||
        value == '[]') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
            highlight ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: highlight
                    ? Colors.green.shade300
                    : Colors.grey.shade200),
          ),
          child: Text(value,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: highlight
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: highlight
                      ? Colors.green.shade900
                      : Colors.black87)),
        ),
      ]),
    );
  }

  Widget _prescRow(String label, String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 95,
            child: Text('$label: ',
                style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _uploadOptionCard({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
          done ? Colors.grey.shade300 : iconColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              radius: 18,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            if (done)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onTap,
              child: loading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text(buttonLabel,
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
