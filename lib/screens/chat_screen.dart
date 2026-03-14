import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../models/message.dart';
import 'upload_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

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

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.surfaceLight,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NeuralKB',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'AI Knowledge Base',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppTheme.divider.withOpacity(0.8), height: 1),
            ),
            const SizedBox(height: 8),

            // ── New Chat ──────────────────────────────────
            _drawerTile(
              icon: Icons.add_circle_outline_rounded,
              label: 'New Chat',
              onTap: () {
                context.read<ChatProvider>().clearMessages();
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 6),
              child: Text(
                'TOOLS',
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
            ),

            // ── Upload ────────────────────────────────────
            _drawerTile(
              icon: Icons.cloud_upload_outlined,
              label: 'Upload Files',
              subtitle: 'Add to knowledge base',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                );
              },
            ),

            // ── Settings ──────────────────────────────────
            _drawerTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              subtitle: 'Model & preferences',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppTheme.divider.withOpacity(0.7), height: 1),
            ),
            const SizedBox(height: 4),

            // ── Sign Out ──────────────────────────────────
            _drawerTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppTheme.error,
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    final labelColor = color ?? AppTheme.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: (color ?? AppTheme.accentBlue).withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: color ?? AppTheme.textSecondary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'NeuralKB',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: AppTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chat, _) => IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              onPressed: () => chat.clearMessages(),
              tooltip: 'New chat',
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────
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

          // ── Error banner ──────────────────────────────
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

          // ── Input bar ─────────────────────────────────
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
          const SizedBox(height: 56),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome, size: 34, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'NeuralKB',
            style: TextStyle(
              fontSize: 26,
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
                  _messageController.text = s['label'] as String;
                  _sendMessage();
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: AppTheme.accentBlue.withOpacity(0.08),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
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
      color: AppTheme.primaryDark,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF202124),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // + button (left)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 6),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UploadScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 4,
                    minLines: 1,
                    enabled: !chat.isThinking,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Message NeuralKB',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.6),
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 6),
                  child: GestureDetector(
                    onTap: chat.isThinking ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: chat.isThinking
                            ? AppTheme.divider
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: chat.isThinking
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.accentBlue,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              color: Color(0xFF131314),
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Source Modal ───────────────────────────────────────────────────────────────

class _SourceModal extends StatelessWidget {
  final Source source;

  const _SourceModal({required this.source});

  @override
  Widget build(BuildContext context) {
    final iconColor = source.isImage
        ? Colors.orange
        : AppTheme.textSecondary;

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
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
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
              child: source.isImage &&
                      (source.dataUrl != null || source.url != null)
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
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppTheme.textSecondary,
          ),
        );
      }
    }

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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
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
