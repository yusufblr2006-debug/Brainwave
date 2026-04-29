import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/case_analysis.dart';
import '../models/lawyer.dart';
import '../models/ocr_result.dart';

class ApiService {
  static Future<T> _req<T>(Future<http.Response> req,
      T Function(Map) parse) async {
    final res = await req;
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(body['detail'] ?? 'Unknown error');
    return parse(body);
  }

  static Future<Map> checkHealth() async {
    if (kMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'status': 'ok'};
    }
    return _req(http.get(Uri.parse('$BASE_URL/api/health')), (b)=>b);
  }

  static Future<String> sendChat(String sessionId, String message) async {
    if (kMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      return 'Based on Indian law, Article 21 guarantees your right to life and personal liberty. You should document all interactions and consult with a legal expert immediately.';
    }
    return _req(http.post(Uri.parse('$BASE_URL/api/chat'),
      headers:{'Content-Type':'application/json'},
      body: jsonEncode({'session_id':sessionId,'message':message})),
    (b) => b['reply'] as String);
  }

  static Future<CaseAnalysis> analyzeCase(String sessionId) async {
    if (kMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      return CaseAnalysis.fromJson({
        'case_summary': 'Possible property encroachment by neighbor on registered land.',
        'applicable_indian_laws': ['IPC Section 441 (Criminal Trespass)', 'Specific Relief Act Section 5'],
        'missing_evidence': ['Updated land survey map', 'Neighbor\'s title deed'],
        'risk_score': 65,
        'case_category': 'Property'
      });
    }
    return _req(http.post(Uri.parse('$BASE_URL/api/analyze-case'),
      headers:{'Content-Type':'application/json'},
      body: jsonEncode({'session_id':sessionId})),
    (b) => CaseAnalysis.fromJson(b as Map<String, dynamic>));
  }

  static Future<List<Lawyer>> matchLawyer(String caseCategory) async {
    if (kMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      return DummyData.lawyers.map((l) => Lawyer.fromJson(Map<String, dynamic>.from(l))).toList();
    }
    return _req(http.post(Uri.parse('$BASE_URL/api/match-lawyer'),
      headers:{'Content-Type':'application/json'},
      body: jsonEncode({'case_category':caseCategory})),
    (b) => (b['lawyers'] as List).map((l)=>Lawyer.fromJson(l as Map<String, dynamic>)).toList());
  }

  static Future<OcrResult> uploadOcr(Uint8List bytes, String filename) async {
    if (kMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      return OcrResult.fromJson({
        'extracted_text': 'EXTRACTED TEXT: Legal notice dated 15/04/2026 regarding vacation of premises...',
        'legal_violations': ['Violates 30-day notice mandate (Rent Control Act)'],
        'recommended_actions': ['File caveat in local court', 'Reply to notice within 7 days']
      });
    }
    final req = http.MultipartRequest('POST', Uri.parse('$BASE_URL/api/ocr'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamedRes = await req.send();
    final res = await http.Response.fromStream(streamedRes);
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(body['detail'] ?? 'OCR Failed');
    return OcrResult.fromJson(body as Map<String, dynamic>);
  }

  static Future<void> registerUser(Map<String, dynamic> data) async {
    if (kMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }
    await _req(http.post(Uri.parse('$BASE_URL/api/register/user'),
      headers:{'Content-Type':'application/json'},
      body: jsonEncode(data)), (b)=>b);
  }

  static Future<Map> geocode(String pinCode) async {
    if (kMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'city': 'Bengaluru', 'state': 'Karnataka'};
    }
    return _req(http.post(Uri.parse('$BASE_URL/api/geocode'),
      headers:{'Content-Type':'application/json'},
      body: jsonEncode({'pin_code':pinCode})), (b)=>b);
  }

  static Future<List<Map<String, dynamic>>> getConversation(String sessionId) async {
    if (kMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      return [];
    }
    return _req(http.get(Uri.parse('$BASE_URL/api/conversation/$sessionId')),
      (b) => (b['messages'] as List).cast<Map<String, dynamic>>());
  }
}
