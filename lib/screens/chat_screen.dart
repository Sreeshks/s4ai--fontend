import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Theme configuration
class AppTheme {
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color userBubbleColor = Color(0xFF6200EE);
  static const Color botBubbleColor = Color(0xFFFFFFFF);
  static const Color userTextColor = Color(0xFFFFFFFF);
  static const Color botTextColor = Color(0xFF333333);
  static const Color hintTextColor = Color(0xFF9E9E9E);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI assistant. How can I help you today?",
      isUser: false,
    ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
      ));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://s4-backend-95fy.onrender.com/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(
            text: data['response'],
            isUser: false,
          ));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, something went wrong. Please try again.',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error connecting to the server. Please try again.',
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text:
                      "Hello! I'm your AI assistant. How can I help you today?",
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                image: const DecorationImage(
                  image: AssetImage('assets/chat_background.png'),
                  opacity: 0.1,
                  fit: BoxFit.cover,
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageBubble(message: message);
                },
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      color: AppTheme.hintTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: AppTheme.hintTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(width: 0, style: BorderStyle.none),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.userBubbleColor
              : AppTheme.botBubbleColor,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: message.isUser
                ? const Radius.circular(18)
                : const Radius.circular(0),
            bottomRight: message.isUser
                ? const Radius.circular(0)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser
                    ? AppTheme.userTextColor
                    : AppTheme.botTextColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _getTimeString(),
                style: TextStyle(
                  color: message.isUser
                      ? AppTheme.userTextColor.withOpacity(0.7)
                      : AppTheme.botTextColor.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeString() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
