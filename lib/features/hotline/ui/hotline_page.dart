import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../services/hotline_service.dart';

class HotlinePage extends StatefulWidget {
  const HotlinePage({super.key});

  @override
  State<HotlinePage> createState() => _HotlinePageState();
}

class _HotlinePageState extends State<HotlinePage> {
  late HotlineService _service;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  bool _isLoading = true;
  bool _isConnected = false;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _service = HotlineService(authService);
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

  Future<void> _connectWebSocket() async {
    final wsUrl = await _service.getWebSocketUrl();
    if (wsUrl == null) {
      if (mounted) setState(() => _error = 'Please login to use hotline');
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _wsSubscription = _channel!.stream.listen(
        (data) {
          if (!mounted) return;
          final message = json.decode(data);
          _handleWebSocketMessage(message);
        },
        onDone: () {
          if (mounted) {
            setState(() => _isConnected = false);
            // Reconnect after a delay
            Future.delayed(const Duration(seconds: 3), () {
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
      // Admin sent a message
      setState(() {
        _messages.add(
          ChatMessage(
            id: message['id'],
            content: message['content'] ?? '',
            role: 'ADMIN',
            createdAt: message['timestamp'] != null
                ? DateTime.parse(message['timestamp'])
                : DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } else if (type == 'message_sent') {
      // Our message was confirmed
      // Already added optimistically, just update ID if needed
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
    _scrollToBottom();

    // Send via WebSocket if connected, otherwise REST
    if (_channel != null && _isConnected) {
      _channel!.sink.add(json.encode({'content': content}));
    } else {
      _service.sendMessage(content);
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Chat Container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Chat Header
                      _buildChatHeader(),

                      // Messages
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _error != null
                            ? Center(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : _buildMessagesList(),
                      ),

                      // Input Area
                      _buildInputArea(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          // Menu/Back Button
          IconButton(
            onPressed: () {
              // Extract eventId from current URL and go back to menu
              final uri = GoRouterState.of(context).uri;
              final pathSegments = uri.pathSegments;
              // URL is /events/{id}/hotline, so id is at index 1
              if (pathSegments.length >= 2 && pathSegments[0] == 'events') {
                final eventId = pathSegments[1];
                context.go('/events/$eventId/menu');
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 10),

          // Title
          const Text(
            'Hotline',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 32,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          // Connection Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
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
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Profile/Notifications
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFCDD1E5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Chat with Organizers',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.videocam_outlined,
              color: Colors.black54,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.phone_outlined,
              color: Colors.black54,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'No messages yet.\nStart a conversation!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length + 1, // +1 for date header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Date header
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _messages.isNotEmpty
                    ? _formatDate(_messages.first.createdAt)
                    : '',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xD4000000),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Admin avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.gradientStart,
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF312F2F),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 12),
            // User avatar placeholder
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Message Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF312F2F),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  // Emoji button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.white54,
                      size: 28,
                    ),
                  ),

                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  // Attachment button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.attach_file,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),

                  // Payment button (from Figma)
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.payment,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),

                  // Camera button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Voice/Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF312F2F),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _messageController.text.isEmpty ? Icons.mic : Icons.send,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
