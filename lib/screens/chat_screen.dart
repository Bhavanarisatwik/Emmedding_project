import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
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
                gradient: LinearGradient(
                  colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'NeuralKB',
              style: TextStyle(fontWeight: FontWeight.w600),
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
                      return const TypingIndicator();
                    }
                    
                    final message = chat.messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MessageBubble(
                        message: message,
                        onSourceTap: message.sources.isNotEmpty
                            ? () => _showSourceModal(message.sources.first)
                            : null,
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
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chat.error!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
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
      {'icon': Icons.description, 'label': 'Summarize my documents'},
      {'icon': Icons.image, 'label': 'Show my uploaded photos'},
      {'icon': Icons.search, 'label': 'Find notes about...'},
      {'icon': Icons.analytics, 'label': 'What did I upload today?'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'NeuralKB',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal AI knowledge base',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: suggestions.map((s) {
              return InkWell(
                onTap: () {
                  _messageController.text = s['label']!;
                  _sendMessage();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s['icon'] as IconData, size: 18, color: AppTheme.accentBlue),
                      const SizedBox(width: 8),
                      Text(
                        s['label'] as String,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        border: Border(
          top: BorderSide(color: AppTheme.divider.withOpacity(0.5)),
        ),
      ),
      child: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          return Row(
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
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your knowledge base...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: chat.isThinking ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: chat.isThinking
                        ? null
                        : LinearGradient(
                            colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                          ),
                    color: chat.isThinking ? AppTheme.surface : null,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: chat.isThinking
                        ? null
                        : [
                            BoxShadow(
                              color: AppTheme.accentBlue.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: chat.isThinking
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 22),
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: source.isImage
                        ? Colors.orange.withOpacity(0.1)
                        : source.isVideo
                            ? Colors.purple.withOpacity(0.1)
                            : AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    source.isImage
                        ? Icons.image
                        : source.isVideo
                            ? Icons.videocam
                            : Icons.description,
                    color: source.isImage
                        ? Colors.orange
                        : source.isVideo
                            ? Colors.purple
                            : AppTheme.accentBlue,
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
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${source.type.toUpperCase()} • ${source.scorePercent}% relevance',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: source.isImage && (source.dataUrl != null || source.url != null)
                  ? _buildImagePreview()
                  : source.contentPreview != null
                      ? Text(
                          source.contentPreview!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        )
                      : const Text(
                          'No preview available',
                          style: TextStyle(color: AppTheme.textSecondary),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
