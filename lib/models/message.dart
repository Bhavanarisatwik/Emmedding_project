class Message {
  final String id;
  final String role;
  final String content;
  final List<Source> sources;
  final DateTime timestamp;
  final bool isThinking;

  Message({
    required this.id,
    required this.role,
    required this.content,
    this.sources = const [],
    DateTime? timestamp,
    this.isThinking = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((s) => Source.fromJson(s))
              .toList() ??
          [],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'sources': sources.map((s) => s.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? role,
    String? content,
    List<Source>? sources,
    DateTime? timestamp,
    bool? isThinking,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      sources: sources ?? this.sources,
      timestamp: timestamp ?? this.timestamp,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}

class ChatSession {
  final String id;
  final DateTime createdAt;
  final List<Message> messages;

  ChatSession({required this.id, required this.createdAt, required this.messages});

  String get preview {
    final first = messages.firstWhere((m) => m.isUser, orElse: () => messages.first);
    final text = first.content;
    return text.length > 55 ? '${text.substring(0, 55)}...' : text;
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => Message.fromJson(m))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}

class Source {
  final String id;
  final double score;
  final Map<String, dynamic> metadata;
  final String? url;

  Source({
    required this.id,
    required this.score,
    required this.metadata,
    this.url,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      metadata: json['metadata'] ?? {},
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score': score,
      'metadata': metadata,
      'url': url,
    };
  }

  String get filename => metadata['filename'] ?? id;
  String get type => metadata['type'] ?? 'text';
  String? get dataUrl => metadata['data_url'];
  String? get userTag => metadata['user_tag'];
  String? get contentPreview => metadata['content_preview'];
  
  int get scorePercent => (score * 100).round();
  
  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isText => type == 'text';
}
