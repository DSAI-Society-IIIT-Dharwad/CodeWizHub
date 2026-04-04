import 'package:appwrite/appwrite.dart';
import 'dart:convert';
import '../appwrite_config.dart';
import 'package:appwrite/models.dart' as models;

class ConsultationService {
  late Client client;
  late Databases databases;

  // ✅ Constructor (FIXED)
  ConsultationService() {
    client = Client()
      ..setEndpoint(AppwriteConfig.endpoint)
      ..setProject(AppwriteConfig.projectId)
      ..setSelfSigned(status: true);

    databases = Databases(client);
  }

  // ── SEARCH PATIENTS BY PHONE NUMBER ────────────────────────────────────
  Future<Map<String, dynamic>> searchPatientsByPhone(String phone) async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.patientsCollection,
        queries: [Query.equal('WhatsApp_Number', phone)],
      );

      if (result.documents.isEmpty) {
        return {'success': false, 'error': 'No patient found with this phone number'};
      }

      return {
        'success': true,
        'patients': result.documents.map((d) => d.data).toList(),
      };
    } on AppwriteException catch (e) {
      return {'success': false, 'error': e.message ?? 'Search failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── GET PATIENT BY ID ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getPatientById(String patientId) async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.patientsCollection,
        queries: [Query.equal('patientId', patientId)],
      );

      if (result.documents.isEmpty) return null;
      return result.documents.first.data;
    } catch (e) {
      return null;
    }
  }

  // ── GET PATIENT HISTORY ───────────────────────────────────────────────
  Future<String> getPatientHistory(String patientId) async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.consultationsCollection,
        queries: [
          Query.equal('patientId', patientId),
          Query.orderDesc('\$createdAt'),
          Query.limit(3),
        ],
      );

      if (result.documents.isEmpty) return 'No previous history';

      return result.documents.map((d) {
        return 'Date: ${d.$createdAt.substring(0, 10)} | Diagnosis: ${d.data['diagnosis'] ?? 'N/A'}';
      }).join('\n');
    } catch (e) {
      return 'No previous history';
    }
  }

  // ── SAVE CONSULTATION ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> saveConsultation({
    required String doctorId,
    required String patientId,
    required String transcript,
    required Map<String, dynamic> opdReport,
    required Map<String, dynamic> prescription,
  }) async {
    try {
      final consultationId = 'CON${DateTime.now().millisecondsSinceEpoch}';

      final doc = await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.consultationsCollection,
        documentId: ID.unique(),
        data: {
          'consultationId': consultationId,
          'doctorId': doctorId,
          'patientId': patientId,
          'transcript': transcript.length > 4900 ? transcript.substring(0, 4900) : transcript,
          'diagnosis': opdReport['diagnosis'] ?? '',
          'symptoms': jsonEncode(opdReport['symptoms'] ?? []),
          'prescription': jsonEncode(prescription['medicines'] ?? []),
          'opdReport': jsonEncode(opdReport),
          'chiefComplaint': opdReport['chief_complaint'] ?? '',
          'advice': opdReport['advice'] ?? '',
          'followUp': opdReport['follow_up'] ?? '',
          'riskAlerts': jsonEncode(opdReport['risk_alerts'] ?? []),
          'status': 'final',
          'imageUrls': '',
          'uploadedToGovt': false,
          'uploadedToStudents': false,
          'studentAccessExpiry': '',
          'attachmentUrls': '',
        },
      );

      return {
        'success': true,
        'consultationId': consultationId,
        'docId': doc.$id,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── GET DOCTOR CONSULTATIONS ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDoctorConsultations(String doctorId) async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.consultationsCollection,
        queries: [
          Query.equal('doctorId', doctorId),
          Query.orderDesc('\$createdAt')
        ],
      );

      return result.documents.map((d) => {
        ...d.data,
        '\$id': d.$id,
        '\$createdAt': d.$createdAt
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ── GET PATIENT CONSULTATIONS ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPatientConsultations(String patientId) async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.consultationsCollection,
        queries: [
          Query.equal('patientId', patientId),
          Query.orderDesc('\$createdAt')
        ],
      );

      return result.documents.map((d) => {
        ...d.data,
        '\$id': d.$id,
        '\$createdAt': d.$createdAt
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ── CREATE UPLOAD RECORD (NEW FIX) ────────────────────────────────────
  Future<Map<String, dynamic>> createUploadRecord({
    required String consultationId,
    required String uploadType, // 'govt' or 'students'
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      final expiry = uploadType == 'students'
          ? DateTime.now().add(const Duration(days: 90)).toIso8601String()
          : '';

      await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'uploads',
        documentId: ID.unique(),
        data: {
          'consultationId': consultationId,
          'uploadType': uploadType,
          'uploadedAt': now,
          'expiresAt': expiry,
        },
      );

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getStudentConsultations() async {
    try {
      final uploadsResult = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'uploads',
        queries: [
          Query.equal('uploadType', 'students'),
          Query.orderDesc('\$createdAt'),
        ],
      );

      final now = DateTime.now();
      final validIds = <String>[];

      for (final doc in uploadsResult.documents) {
        final expiry = doc.data['expiresAt'];

        if (expiry != null && expiry.toString().isNotEmpty) {
          try {
            if (DateTime.parse(expiry).isAfter(now)) {
              validIds.add(doc.data['consultationId']);
            }
          } catch (_) {}
        } else {
          validIds.add(doc.data['consultationId']);
        }
      }

      if (validIds.isEmpty) return [];

      List<Map<String, dynamic>> result = [];

      for (final id in validIds) {
        final docs = await databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.consultationsCollection,
          queries: [Query.equal('consultationId', id)],
        );

        if (docs.documents.isNotEmpty) {
          final d = docs.documents.first;
          result.add({
            ...d.data,
            '\$id': d.$id,
            '\$createdAt': d.$createdAt,
          });
        }
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  // ── UPLOAD FILE ───────────────────────────────────────────────────────
  Future<String?> uploadAttachment(String filePath, String fileName) async {
    try {
      final storage = Storage(client);

      final result = await storage.createFile(
        bucketId: 'medibridge_files',
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
      );

      return '${AppwriteConfig.endpoint}/storage/buckets/medibridge_files/files/${result.$id}/view?project=${AppwriteConfig.projectId}';
    } catch (e) {
      return null;
    }
  }

  // ── SAVE ATTACHMENTS ──────────────────────────────────────────────────
  Future<void> saveAttachments(String docId, List<String> urls) async {
    try {
      await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.consultationsCollection,
        documentId: docId,
        data: {'attachmentUrls': jsonEncode(urls)},
      );
    } catch (e) {}
  }

  // ── SEARCH (AI) ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> semanticSearch({
    required String query,
    required String role,
    String? doctorId,
  }) async {
    try {
      List<models.Document> docs;

      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.consultationsCollection,
        queries: role == 'student'
            ? [Query.equal('uploadedToStudents', true)]
            : [Query.equal('doctorId', doctorId ?? '')],
      );

      docs = result.documents;

      if (docs.isEmpty) return [];

      final keywords = query.toLowerCase().split(' ').where((w) => w.length > 2);

      final scored = docs.map((d) {
        final data = d.data;
        final text = [
          data['diagnosis'] ?? '',
          data['symptoms'] ?? '',
          data['chiefComplaint'] ?? '',
          data['transcript'] ?? '',
        ].join(' ').toLowerCase();

        int score = 0;
        for (final kw in keywords) {
          if (text.contains(kw)) score++;
        }

        return {'score': score, 'data': d};
      }).where((e) => (e['score'] as int) > 0).toList();

      scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      return scored.map((s) => {
        ...((s['data'] as models.Document).data),
        '\$id': (s['data'] as models.Document).$id
      }).toList();
    } catch (e) {
      return [];
    }
  }
  // ── CHECK UPLOAD STATUS FROM UPLOADS COLLECTION ────────────────────────
  Future<Map<String, bool>> checkUploadStatus(String consultationId) async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.uploadsCollection,
        queries: [Query.equal('consultationId', consultationId)],
      );

      bool govtDone = false;
      bool studentsDone = false;

      for (final doc in result.documents) {
        final type = doc.data['uploadType'];
        if (type == 'govt') {
          govtDone = true;
        }
        if (type == 'students') {
          final expiry = doc.data['expiresAt'];
          if (expiry != null && expiry.toString().isNotEmpty) {
            try {
              studentsDone = DateTime.parse(expiry).isAfter(DateTime.now());
            } catch (_) {
              studentsDone = true;
            }
          } else {
            studentsDone = true;
          }
        }
      }

      print('checkUploadStatus: $consultationId → govt=$govtDone, students=$studentsDone');
      return {'govt': govtDone, 'students': studentsDone};

    } catch (e) {
      print('checkUploadStatus error: $e');
      return {'govt': false, 'students': false};
    }
  }
}
