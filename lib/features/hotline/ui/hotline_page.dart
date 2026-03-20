import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/hotline_providers.dart';
import '../services/hotline_service.dart';

class HotlinePage extends ConsumerStatefulWidget {
  const HotlinePage({super.key});

  @override
  ConsumerState<HotlinePage> createState() => _HotlinePageState();
}

class _HotlinePageState extends ConsumerState<HotlinePage> {
  late HotlineService _service;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  bool _isLoading = true;
  bool _isConnected = false;
  String? _error;
  bool _initialized = false;
  bool _showEmojiPicker = false;
  bool _isSendingFile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _service = ref.read(hotlineServiceProvider);
      _initialized = true;
      _loadHistory();
      _connectWebSocket();
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final messages = await _service.getChatHistory();
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load messages';
        _isLoading = false;
      });
    }
  }

  int _wsRetryCount = 0;
  static const _maxWsRetries = 3;

  Future<void> _connectWebSocket() async {
    final wsUrl = await _service.getWebSocketUrl();
    if (wsUrl == null) {
      // No token — can't connect, use REST only
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _wsSubscription = _channel!.stream.listen(
        (data) {
          if (!mounted) return;
          _wsRetryCount = 0; // reset on successful message
          final message = json.decode(data);
          _handleWebSocketMessage(message);
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isConnected = false);
          _wsRetryCount++;
          if (_wsRetryCount < _maxWsRetries) {
            Future.delayed(Duration(seconds: 5 * _wsRetryCount), () {
              if (mounted) _connectWebSocket();
            });
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isConnected = false);
        },
      );

      if (mounted) setState(() => _isConnected = true);
    } catch (e) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'];

    if (type == 'message') {
      setState(() {
        _messages.add(
          ChatMessage(
            id: message['id'],
            content: message['content'] ?? '',
            role: 'ADMIN',
            createdAt: message['timestamp'] != null
                ? DateTime.parse(message['timestamp'])
                : DateTime.now(),
            mediaUrl: message['media_url'],
          ),
        );
      });
      _scrollToBottom();
    } else if (type == 'message_sent') {
      // Our message was confirmed — already added optimistically
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Add message optimistically
    setState(() {
      _messages.add(
        ChatMessage(content: content, role: 'USER', createdAt: DateTime.now()),
      );
    });
    _messageController.clear();
    _messageFocusNode.requestFocus();
    _scrollToBottom();

    // Send via WebSocket if connected, otherwise REST
    if (_channel != null && _isConnected) {
      _channel!.sink.add(json.encode({'content': content}));
    } else {
      _service.sendMessage(content);
    }
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start < 0 ? text.length : selection.start,
      selection.end < 0 ? text.length : selection.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.start < 0 ? text.length : selection.start) +
            emoji.length,
      ),
    );
    setState(() {});
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx', 'xls', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isSendingFile = true);

    try {
      final token = await ref.read(authNotifierProvider.notifier).getToken();
      if (token == null) return;

      final uri = Uri.parse('${AppConfig.b2cApiBaseUrl}/api/v1/chat/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
          contentType: MediaType.parse(_getMimeType(file.name)),
        ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final respBody = await response.stream.bytesToString();
        final data = json.decode(respBody);
        final url = data['url'] as String;

        // Send message with media URL
        _sendMediaMessage(url, file.name);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('File upload error: $e');
    } finally {
      if (mounted) setState(() => _isSendingFile = false);
    }
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  void _sendMediaMessage(String mediaUrl, String fileName) {
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .any((ext) => fileName.toLowerCase().endsWith(ext));
    final content = isImage ? '[Image]' : '[File: $fileName]';

    setState(() {
      _messages.add(ChatMessage(
        content: content,
        role: 'USER',
        createdAt: DateTime.now(),
        mediaUrl: mediaUrl,
      ));
    });
    _scrollToBottom();

    if (_channel != null && _isConnected) {
      _channel!.sink.add(json.encode({
        'content': content,
        'media_url': mediaUrl,
      }));
    } else {
      _service.sendMessageWithMedia(content, mediaUrl);
    }
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

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  String _formatDate(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return 'Today, ${_formatTime(time)}';
    }
    return '${time.day}/${time.month}/${time.year}, ${_formatTime(time)}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(
                'Hotline',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              // Connection status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isConnected
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnected ? 'Online' : 'Offline',
                      style: GoogleFonts.inter(
                        color: _isConnected ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chat container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Chat header
                  _buildChatHeader(isMobile),

                  // Messages
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryColor),
                          )
                        : _error != null
                            ? Center(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : _buildMessagesList(),
                  ),

                  // Emoji picker
                  if (_showEmojiPicker) _buildEmojiPicker(),

                  // File sending indicator
                  if (_isSendingFile)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sending file...',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Input area
                  _buildInputArea(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: const Icon(
              Icons.support_agent,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat with Organizers',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  _isConnected ? 'Available now' : 'Connecting...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Coming soon',
            child: IconButton(
              onPressed: null,
              icon: Icon(
                Icons.videocam_outlined,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ),
          ),
          Tooltip(
            message: 'Coming soon',
            child: IconButton(
              onPressed: null,
              icon: Icon(
                Icons.phone_outlined,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a conversation with the organizers',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _messages.isNotEmpty
                    ? _formatDate(_messages.first.createdAt)
                    : '',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          );
        }

        final message = _messages[index - 1];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isFromUser;

    final bubbleBg = isUser
        ? AppTheme.primaryColor
        : Colors.grey.shade100;
    final textColor = isUser ? Colors.white : Colors.black87;
    final timeColor = isUser
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.grey.shade500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(
                Icons.support_agent,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.mediaUrl != null &&
                      message.mediaUrl!.isNotEmpty) ...[
                    if (_isImageUrl(message.mediaUrl!))
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse(message.mediaUrl!), mode: LaunchMode.externalApplication),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.mediaUrl!,
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse(message.mediaUrl!), mode: LaunchMode.externalApplication),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download, color: textColor, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                message.content,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: textColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                  if (message.mediaUrl == null ||
                      !_isImageUrl(message.mediaUrl ?? ''))
                    Text(
                      message.content,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: GoogleFonts.inter(fontSize: 11, color: timeColor),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: const Icon(Icons.person,
                  color: AppTheme.primaryColor, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    const emojis = [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗',
      '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭',
      '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏',
      '😒', '🙄', '😬', '😮', '😯', '😲', '😳', '🥺',
      '😦', '😧', '😨', '😰', '😥', '😢', '😭', '😱',
      '👍', '👎', '👌', '✌️', '🤞', '🤝', '🙏', '💪',
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🎉', '🎊', '🏆', '🥇', '⭐', '🌟', '💯', '✅',
      '🔥', '💡', '📎', '📁', '📅', '🕐', '📍', '🏢',
    ];

    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      height: isMobile ? 160 : 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMobile ? 6 : 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _insertEmoji(emojis[index]),
            child: Center(
              child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    final hasText = _messageController.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Emoji toggle
            _InputIconButton(
              onPressed: _toggleEmojiPicker,
              icon: _showEmojiPicker
                  ? Icons.keyboard
                  : Icons.emoji_emotions_outlined,
            ),
            const SizedBox(width: 12),

            // Text field — matches the grey container's pill shape
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
                cursorColor: AppTheme.primaryColor,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1.5),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),

            // Attachment
            _InputIconButton(
              onPressed: _isSendingFile ? null : _pickAndSendFile,
              icon: Icons.attach_file,
            ),
            const SizedBox(width: 8),

            // Send / Mic button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasText
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasText ? Icons.send_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Consistent icon button used outside the text field in the chat input bar.
class _InputIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;

  const _InputIconButton({required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        color: Colors.grey.shade500,
        splashRadius: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}
