import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  // ⚠️ UPDATE THIS URL when deploying to production
  // For local testing: 'http://localhost:5000'
  // For Vercel deployment: 'https://your-vercel-app.vercel.app'
  static const String baseUrl = 'https://personal-knowledge-base-mj26ilu05.vercel.app';
  
  static const String chatEndpoint = '/api/chat';
  static const String uploadEndpoint = '/api/upload';
  static const String searchEndpoint = '/api/search';

  final http.Client _client;
  
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<({String answer, List<Source> sources})> sendChatMessage({
    required String message,
    String model = 'kimi-k2.5',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$chatEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'model': model}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer']?.toString() ?? '';
        final sources = (data['sources'] as List<dynamic>?)
                ?.map((s) => Source.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [];
        return (answer: answer, sources: sources);
      } else if (response.statusCode == 429) {
        throw ApiException('Rate limit reached. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['error'] ?? 'Request failed');
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<({String id, String filename, String subfolder})> uploadFile({
    required File file,
    String? tag,
    Function(int)? onProgress,
  }) async {
    http.Client? client;
    try {
      // Create a new client with longer timeout
      client = http.Client();
      final uri = Uri.parse('$baseUrl$uploadEndpoint');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      // Add tag if provided
      if (tag != null && tag.isNotEmpty) {
        request.fields['tag'] = tag;
      }
      
      // Add headers
      request.headers['Accept'] = 'application/json';

      // Send request
      final streamedResponse = await client.send(request).timeout(const Duration(minutes: 5));
      
      // Report progress
      if (onProgress != null) {
        onProgress(100);
      }
      
      // Get response body
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (
          id: data['id']?.toString() ?? '',
          filename: data['filename']?.toString() ?? '',
          subfolder: data['subfolder']?.toString() ?? '',
        );
      } else {
        String errorMsg = 'Upload failed: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['error'] ?? errorMsg;
        } catch (_) {}
        throw ApiException(errorMsg);
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw ApiException('Upload timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Upload failed: $e');
    } finally {
      client?.close();
    }
  }

  Future<List<Source>> search(String query, {int topK = 5}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$searchEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query, 'top_k': topK}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['results'] as List<dynamic>?)
                ?.map((r) => Source.fromJson(r))
                .toList() ??
            [];
      } else {
        throw ApiException('Search failed');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Search error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
