import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/case_analysis.dart';

class AppProvider extends ChangeNotifier {
  String sessionId = const Uuid().v4();
  List<ChatMessage> messages = [];
  CaseAnalysis? caseAnalysis;
  bool wsConnected = false;

  // Auth state
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhone;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    userName = prefs.getString('user_name');
    userEmail = prefs.getString('user_email');
    userPhone = prefs.getString('user_phone');
    notifyListeners();
  }

  Future<void> login(String id, String name, String email, [String? phone]) async {
    final prefs = await SharedPreferences.getInstance();
    userId = id; userName = name; userEmail = email; userPhone = phone;
    await prefs.setString('user_id', id);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    if (phone != null) await prefs.setString('user_phone', phone);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    userId = userName = userEmail = userPhone = null;
    notifyListeners();
  }

  void newSession() {
    sessionId = const Uuid().v4();
    messages.clear(); caseAnalysis = null;
    notifyListeners();
  }
  void addMessage(ChatMessage m) { messages.add(m); notifyListeners(); }
  void setCaseAnalysis(CaseAnalysis c) { caseAnalysis=c; notifyListeners(); }
  void setWs(bool v) { wsConnected=v; notifyListeners(); }
}
