import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  List<Message> _messages = [];
  bool _isThinking = false;
  String? _error;
  String _selectedModel = 'kimi-k2.5';

  ChatProvider({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  List<Message> get messages => _messages;
  bool get isThinking => _isThinking;
  String? get error => _error;
  String get selectedModel => _selectedModel;

  void setModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isThinking) return;

    // Add user message
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

      // Add AI response
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
    _messages = [];
    _error = null;
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
