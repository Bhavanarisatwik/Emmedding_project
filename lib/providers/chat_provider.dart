import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Message> _messages = [];
  bool _isThinking = false;
  String? _error;
  String _selectedModel = 'kimi-k2.5';
  List<ChatSession> _sessions = [];

  ChatProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _loadSessions();
  }

  List<Message> get messages => _messages;
  bool get isThinking => _isThinking;
  String? get error => _error;
  String get selectedModel => _selectedModel;
  List<ChatSession> get sessions => _sessions;

  void setModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('chat_sessions');
      if (raw \!= null) {
        final list = jsonDecode(raw) as List;
        _sessions = list.map((e) => ChatSession.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'chat_sessions',
        jsonEncode(_sessions.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
  }

  void _archiveCurrentSession() {
    if (_messages.isEmpty) return;
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: _messages.first.timestamp,
      messages: List.from(_messages),
    );
    _sessions = [session, ..._sessions].take(10).toList();
    _saveSessions();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isThinking) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content.trim(),
    );
    _messages = [..._messages, userMessage];
    _error = null;
    _isThinking = true;
    notifyListeners();

    try {
      final response = await _apiService.sendChatMessage(
        message: content.trim(),
        model: _selectedModel,
      );

      final assistantMessage = Message(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: response.answer,
        sources: response.sources,
      );
      _messages = [..._messages, assistantMessage];
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred';
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _archiveCurrentSession();
    _messages = [];
    _error = null;
    notifyListeners();
  }

  void loadSession(ChatSession session) {
    _archiveCurrentSession();
    _messages = List.from(session.messages);
    _error = null;
    notifyListeners();
  }

  void deleteSession(String sessionId) {
    _sessions = _sessions.where((s) => s.id \!= sessionId).toList();
    _saveSessions();
    notifyListeners();
  }

  void dismissError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
