import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'message_bubble.dart';



class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  const ChatScreen({super.key, required this.chatId, required this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();

  // Store the message being replied to
  Map<String, dynamic>? _replyingToMessage;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _chatService.sendMessage(
      widget.chatId,
      text,
      replyToMessageId: _replyingToMessage?['id'],
      replyToText: _replyingToMessage?['text'],
    );

    _controller.clear();
    setState(() {
      _replyingToMessage = null; // Clear reply after sending
    });
  }

  void _setReplyMessage(String messageId, String text, String senderId) {
    setState(() {
      _replyingToMessage = {
        'id': messageId,
        'text': text,
        'senderId': senderId,
      };
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesSeen(widget.chatId);

    _chatService.getMessages(widget.chatId).listen((snapshot) {
      for (var msg in snapshot.docs) {
        if (msg['senderId'] != _chatService.currentUserId && msg['seen'] == false) {
          msg.reference.update({'seen': true});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,   // ✅ Gradient behind AppBar
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,   // ✅ Transparent AppBar
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.otherUserName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),  // Hot pink
              Color(0xFFFFB6C1),  // Light pink
              Colors.white,       // White
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['senderId'] == _chatService.currentUserId;

                        final data = msg.data() as Map<String, dynamic>?;

                        return MessageBubble(
                          messageId: msg.id,
                          text: data?['text'] ?? '',
                          isMe: isMe,
                          imageUrl: data?['imageUrl'] ?? '',
                          seen: data?['seen'] ?? false,
                          replyToText: data?['replyToText'],
                          onReply: () => _setReplyMessage(
                            msg.id,
                            data?['text'] ?? '',
                            data?['senderId'] ?? '',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              if (_replyingToMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        color: Colors.pink,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _replyingToMessage!['senderId'] == _chatService.currentUserId
                                  ? 'You'
                                  : widget.otherUserName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _replyingToMessage!['text'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _cancelReply,
                      ),
                    ],
                  ),
                ),

              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.pink,
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
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

}
