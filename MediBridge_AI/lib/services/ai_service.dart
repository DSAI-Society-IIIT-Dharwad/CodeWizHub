import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String groqApiKey =
      'API_Key , Not for you, Ha Ha';
  static const String geminiApiKey =
      'API_Key , Not for you, Ha Ha';

  // Groq LLaMA — primary for BOTH report generation AND translation
  // Free tier: 30 req/min, no daily quota exhaustion like Gemini
  static const String groqChatModel = 'llama-3.3-70b-versatile';
  // Gemini — fallback only
  static const String geminiModel = 'gemini-2.0-flash';

  // ── STEP 1: Audio → Transcript via Groq Whisper ───────────────────────
  Future<Map<String, dynamic>> transcribeAudio(String audioFilePath) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        return {'success': false, 'error': 'Audio file not found'};
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );
      request.headers['Authorization'] = 'Bearer $groqApiKey';
      request.files
          .add(await http.MultipartFile.fromPath('file', audioFilePath));
      request.fields['model'] = 'whisper-large-v3';
      request.fields['response_format'] = 'text';

      final response =
      await request.send().timeout(const Duration(seconds: 60));
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {'success': true, 'transcript': body.trim()};
      }
      return {'success': false, 'error': 'Groq Whisper error: $body'};
    } catch (e) {
      return {'success': false, 'error': 'Transcription error: $e'};
    }
  }

  // ── STEP 2: Transcript → OPD Report + Prescription ────────────────────
  // Groq LLaMA PRIMARY → Gemini FALLBACK
  Future<Map<String, dynamic>> generateBothOutputs({
    required String transcript,
    required String patientName,
    required String patientId,
    required String doctorName,
    required String doctorId,
    String? pastHistory,
  }) async {
    final groqResult = await _generateWithGroq(
      transcript: transcript,
      patientName: patientName,
      patientId: patientId,
      doctorName: doctorName,
      doctorId: doctorId,
      pastHistory: pastHistory,
    );
    if (groqResult['success'] == true) return groqResult;

    print('Groq failed (${groqResult['error']}) — trying Gemini fallback...');
    return await _generateWithGemini(
      transcript: transcript,
      patientName: patientName,
      patientId: patientId,
      doctorName: doctorName,
      doctorId: doctorId,
      pastHistory: pastHistory,
    );
  }

  // ── Groq LLaMA: report generation (PRIMARY) ───────────────────────────
  Future<Map<String, dynamic>> _generateWithGroq({
    required String transcript,
    required String patientName,
    required String patientId,
    required String doctorName,
    required String doctorId,
    String? pastHistory,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final safePatientName = patientName.replaceAll('"', '');
    final safePatientId = patientId.replaceAll('"', '');
    final safeDoctorName = doctorName.replaceAll('"', '');
    final safeDoctorId = doctorId.replaceAll('"', '');

    final systemPrompt =
        'You are a medical AI assistant. Generate structured medical reports '
        'from doctor-patient consultation transcripts. '
        'The transcript may be in any Indian language (Hindi, Kannada, Tamil, '
        'Telugu, Marathi, Bengali, etc.) or English. Always respond in English. '
        'Respond with ONLY valid JSON. No markdown, no explanation, no extra text.';

    final userPrompt =
        'Generate a medical OPD report and prescription from this consultation.\n\n'
        'Patient: $safePatientName (ID: $safePatientId)\n'
        'Doctor: $safeDoctorName (ID: $safeDoctorId)\n'
        'Date: $dateStr\n'
        '${pastHistory != null && pastHistory.isNotEmpty ? 'Past Medical History: $pastHistory\n' : ''}'
        '\nTranscript:\n$transcript\n\n'
        'Respond ONLY with this exact JSON structure:\n'
        '{\n'
        '  "opd_report": {\n'
        '    "patient_name": "$safePatientName",\n'
        '    "patient_id": "$safePatientId",\n'
        '    "doctor_name": "$safeDoctorName",\n'
        '    "doctor_id": "$safeDoctorId",\n'
        '    "date": "$dateStr",\n'
        '    "chief_complaint": "...",\n'
        '    "symptoms": ["symptom1", "symptom2"],\n'
        '    "medical_history": "...",\n'
        '    "observations": "...",\n'
        '    "diagnosis": "...",\n'
        '    "advice": "...",\n'
        '    "follow_up": "...",\n'
        '    "risk_alerts": []\n'
        '  },\n'
        '  "prescription": {\n'
        '    "patient_name": "$safePatientName",\n'
        '    "date": "$dateStr",\n'
        '    "doctor_name": "$safeDoctorName",\n'
        '    "medicines": [\n'
        '      {\n'
        '        "name": "medicine name",\n'
        '        "dosage": "e.g. 500mg",\n'
        '        "frequency": "e.g. twice daily",\n'
        '        "duration": "e.g. 5 days",\n'
        '        "instructions": "e.g. after food"\n'
        '      }\n'
        '    ],\n'
        '    "additional_notes": "..."\n'
        '  }\n'
        '}';

    return await _groqChatCall(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      parseReport: true,
    );
  }

  // ── Gemini: report generation (FALLBACK only) ─────────────────────────
  Future<Map<String, dynamic>> _generateWithGemini({
    required String transcript,
    required String patientName,
    required String patientId,
    required String doctorName,
    required String doctorId,
    String? pastHistory,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final safePatientName = patientName.replaceAll('"', '');
    final safePatientId = patientId.replaceAll('"', '');
    final safeDoctorName = doctorName.replaceAll('"', '');
    final safeDoctorId = doctorId.replaceAll('"', '');

    final prompt =
        'You are a medical AI. Generate a JSON report from this consultation.\n'
        'Transcript may be in any Indian language — always respond in English.\n\n'
        'Patient: $safePatientName (ID: $safePatientId)\n'
        'Doctor: $safeDoctorName (ID: $safeDoctorId)\n'
        'Date: $dateStr\n'
        '${pastHistory != null && pastHistory.isNotEmpty ? 'History: $pastHistory\n' : ''}'
        '\nTranscript: $transcript\n\n'
        'Return ONLY valid JSON with opd_report and prescription fields.';

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('Gemini fallback attempt $attempt...');
        final response = await http
            .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/'
                '$geminiModel:generateContent?key=$geminiApiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 2048,
              'responseMimeType': 'application/json',
            },
          }),
        )
            .timeout(const Duration(seconds: 60));

        print('Gemini fallback status: ${response.statusCode}');

        if (response.statusCode == 429) {
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 20));
            continue;
          }
          return {
            'success': false,
            'error': 'AI rate limit. Please wait 1-2 minutes and try again.'
          };
        }
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
          text = _stripFences(text);
          try {
            final parsed = jsonDecode(text);
            return {
              'success': true,
              'opd_report': parsed['opd_report'],
              'prescription': parsed['prescription'],
            };
          } catch (_) {
            final repaired = _repairJson(text);
            try {
              final parsed = jsonDecode(repaired);
              return {
                'success': true,
                'opd_report': parsed['opd_report'],
                'prescription': parsed['prescription'],
              };
            } catch (e) {
              if (attempt < 3) continue;
            }
          }
        }
        return {
          'success': false,
          'error': 'Gemini error ${response.statusCode}'
        };
      } catch (e) {
        print('Gemini fallback attempt $attempt exception: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 5));
        } else {
          return {'success': false, 'error': 'Gemini fallback failed: $e'};
        }
      }
    }
    return {'success': false, 'error': 'All AI services failed. Try again.'};
  }

  // ── STEP 3: Translate OPD text — Groq LLaMA PRIMARY ──────────────────
  // Groq is used here too so Gemini quota is never touched for translation.
  // Result is cached in consultation_detail_screen so called only once per language.
  Future<String> translateOpdBlock(
      String englishText, String targetLanguage) async {
    print('translateOpdBlock: translating to $targetLanguage via Groq...');

    final systemPrompt =
        'You are a medical translator. Translate medical OPD reports accurately. '
        'Return ONLY the translated text. No explanations, no notes, no markdown.';

    final userPrompt =
        'Translate the following medical OPD report completely to $targetLanguage language.\n'
        'Translate ALL content including section headings (Chief Complaint, Symptoms, etc.).\n'
        'Keep the exact same format — each section on a new line with the heading.\n'
        'Return ONLY the translated text:\n\n'
        '$englishText';

    // Try Groq first
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('Groq translation attempt $attempt...');
        final response = await http
            .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $groqApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': groqChatModel,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.1,
            'max_tokens': 1500,
            // No json_object mode here — we want plain text back
          }),
        )
            .timeout(const Duration(seconds: 40));

        print('Groq translation status: ${response.statusCode}');

        if (response.statusCode == 429) {
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 5));
            continue;
          }
          break; // fall through to Gemini
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text =
          data['choices'][0]['message']['content'] as String;
          print('Groq translation success');
          return text.trim();
        }

        break; // unexpected status — try Gemini
      } catch (e) {
        print('Groq translation attempt $attempt error: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 3));
        }
      }
    }

    // Gemini fallback for translation
    print('Groq translation failed — trying Gemini fallback...');
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await http
            .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/'
                '$geminiModel:generateContent?key=$geminiApiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': userPrompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 1500,
            },
          }),
        )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
          return text.trim();
        }
        if (response.statusCode == 429 && attempt < 2) {
          await Future.delayed(const Duration(seconds: 15));
        }
      } catch (e) {
        print('Gemini translation fallback error: $e');
      }
    }

    // Return English as last resort
    print('All translation attempts failed — returning English');
    return englishText;
  }

  // ── Legacy alias — keeps other files working ──────────────────────────
  Future<String> translateForPatient(
      String englishText, String targetLanguage) {
    return translateOpdBlock(englishText, targetLanguage);
  }

  // ── Internal Groq chat helper (for report generation) ─────────────────
  Future<Map<String, dynamic>> _groqChatCall({
    required String systemPrompt,
    required String userPrompt,
    bool parseReport = false,
  }) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('Groq chat attempt $attempt...');
        final response = await http
            .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $groqApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': groqChatModel,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.1,
            'max_tokens': 2048,
            'response_format': {'type': 'json_object'},
          }),
        )
            .timeout(const Duration(seconds: 60));

        print('Groq chat status: ${response.statusCode}');

        if (response.statusCode == 429) {
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 5));
            continue;
          }
          return {'success': false, 'error': 'Groq rate limit'};
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String text = data['choices'][0]['message']['content'] as String;
          text = _stripFences(text);

          if (!parseReport) {
            return {'success': true, 'text': text};
          }

          try {
            final parsed = jsonDecode(text);
            return {
              'success': true,
              'opd_report': parsed['opd_report'],
              'prescription': parsed['prescription'],
            };
          } catch (e) {
            print('JSON parse failed: $e — trying repair...');
            final repaired = _repairJson(text);
            try {
              final parsed = jsonDecode(repaired);
              return {
                'success': true,
                'opd_report': parsed['opd_report'],
                'prescription': parsed['prescription'],
              };
            } catch (repairError) {
              print('Repair failed: $repairError');
              if (attempt < 3) continue;
            }
          }
        }

        return {
          'success': false,
          'error': 'Groq error ${response.statusCode}: ${response.body}'
        };
      } catch (e) {
        print('Groq chat attempt $attempt exception: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 3));
        } else {
          return {'success': false, 'error': 'Groq failed: $e'};
        }
      }
    }
    return {'success': false, 'error': 'Groq failed after all attempts'};
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  String _stripFences(String text) {
    text = text.trim();
    if (text.startsWith('```json')) text = text.substring(7);
    if (text.startsWith('```')) text = text.substring(3);
    if (text.endsWith('```')) text = text.substring(0, text.length - 3);
    return text.trim();
  }

  String _repairJson(String text) {
    text = text.replaceAll(RegExp(r',\s*}'), '}');
    text = text.replaceAll(RegExp(r',\s*]'), ']');

    int braceCount = 0;
    int lastCompleteIndex = -1;
    bool inString = false;
    bool escape = false;

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (escape) { escape = false; continue; }
      if (ch == '\\' && inString) { escape = true; continue; }
      if (ch == '"') { inString = !inString; continue; }
      if (!inString) {
        if (ch == '{') braceCount++;
        if (ch == '}') {
          braceCount--;
          if (braceCount == 0) lastCompleteIndex = i;
        }
      }
    }

    if (lastCompleteIndex > 0) {
      text = text.substring(0, lastCompleteIndex + 1);
    }
    return text;
  }
}
