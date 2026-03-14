import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _messageController.clear();
    _focusNode.unfocus();

    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _showSourceModal(Source source) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SourceModal(source: source),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGlow.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'NeuralKB',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
          ],
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chat, _) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear') {
                  chat.clearMessages();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Clear chat'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                _scrollToBottom();

                if (chat.messages.isEmpty && !chat.isThinking) {
                  return _buildWelcome();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: chat.messages.length + (chat.isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chat.messages.length && chat.isThinking) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: TypingIndicator(),
                      );
                    }

                    final message = chat.messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MessageBubble(
                        message: message,
                        onSourceTap: _showSourceModal,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Error banner
          Consumer<ChatProvider>(
            builder: (context, chat, _) {
              if (chat.error == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chat.error!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: AppTheme.error,
                      onPressed: () => chat.dismissError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    final suggestions = <Map<String, dynamic>>[
      {'icon': Icons.description_outlined, 'label': 'Summarize my documents'},
      {'icon': Icons.image_outlined, 'label': 'Show my uploaded photos'},
      {'icon': Icons.search_rounded, 'label': 'Find notes about...'},
      {'icon': Icons.analytics_outlined, 'label': 'What did I upload today?'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 64),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGlow.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'NeuralKB',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your personal AI knowledge base',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: suggestions.map((s) {
              return InkWell(
                onTap: () {
                  _messageController.text = s['label']!;
                  _sendMessage();
                },
                borderRadius: BorderRadius.circular(14),
                splashColor: AppTheme.accentBlue.withOpacity(0.1),
                highlightColor: AppTheme.accentBlue.withOpacity(0.05),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s['icon'] as IconData, size: 16, color: AppTheme.accentBlue),
                      const SizedBox(width: 8),
                      Text(
                        s['label'] as String,
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        border: Border(
          top: BorderSide(color: AppTheme.divider.withOpacity(0.6)),
        ),
      ),
      child: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: 4,
                  minLines: 1,
                  enabled: !chat.isThinking,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your knowledge base...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.45)),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: AppTheme.divider.withOpacity(0.8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: AppTheme.accentBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: chat.isThinking ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: chat.isThinking
                        ? null
                        : const LinearGradient(
                            colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: chat.isThinking ? AppTheme.surface : null,
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: chat.isThinking
                        ? null
                        : [
                            BoxShadow(
                              color: AppTheme.accentGlow.withOpacity(0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: chat.isThinking
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SourceModal extends StatelessWidget {
  final Source source;

  const _SourceModal({required this.source});

  @override
  Widget build(BuildContext context) {
    final iconColor = source.isImage
        ? Colors.orange
        : source.isVideo
            ? const Color(0xFFA855F7)
            : AppTheme.accentBlue;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: AppTheme.divider),
          left: BorderSide(color: AppTheme.divider),
          right: BorderSide(color: AppTheme.divider),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.2)),
                  ),
                  child: Icon(
                    source.isImage
                        ? Icons.image_outlined
                        : source.isVideo
                            ? Icons.videocam_outlined
                            : Icons.description_outlined,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.filename,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${source.type.toUpperCase()} • ${source.scorePercent}% relevance',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textSecondary.withOpacity(0.7)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.divider.withOpacity(0.6)),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: source.isImage && (source.dataUrl != null || source.url != null)
                  ? _buildImagePreview()
                  : source.contentPreview != null
                      ? SelectableText(
                          source.contentPreview!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.65,
                          ),
                        )
                      : Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Icon(
                                Icons.preview_outlined,
                                size: 40,
                                color: AppTheme.textSecondary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No preview available',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final imageUrl = source.dataUrl ?? source.url;
    if (imageUrl == null) return const SizedBox.shrink();

    // Base64 data URL (e.g. "data:image/jpeg;base64,...")
    if (imageUrl.startsWith('data:')) {
      try {
        final b64 = imageUrl.split(',').last;
        final bytes = base64Decode(b64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image_outlined, size: 48, color: AppTheme.textSecondary),
        );
      }
    }

    // Relative path — prepend server base URL
    final resolvedUrl = imageUrl.startsWith('/')
        ? '${ApiService.baseUrl}$imageUrl'
        : imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        resolvedUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, __, ___) => Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: AppTheme.textSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
