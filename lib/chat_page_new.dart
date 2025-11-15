import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Example: wire this from your button:
/// onPressed: () {
///   Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(vendorName: 'Moonlight Entertainments')));
/// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
//
// class ChatPage extends StatefulWidget {
//   final String vendorId;     // vendor unique id
//   final String vendorName;   // vendor name
//
//   const ChatPage({
//     Key? key,
//     required this.vendorId,
//     required this.vendorName,
//   }) : super(key: key);
//
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final Color accent = const Color(0xFFE91E63);
//
//   String currentUserId = "user_123"; // you can replace this with your logged-in user id
//
//   /// Collection path: chats/{chatId}/messages/{message}
//   /// chatId is generated using both ids (user_vendor)
//   String get chatId =>
//       currentUserId.hashCode <= widget.vendorId.hashCode
//           ? '${currentUserId}_${widget.vendorId}'
//           : '${widget.vendorId}_${currentUserId}';
//
//   void _sendMessage() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;
//
//     final msg = {
//       "text": text,
//       "senderId": currentUserId,
//       "timestamp": FieldValue.serverTimestamp(),
//     };
//
//     await FirebaseFirestore.instance
//         .collection("chats")
//         .doc(chatId)
//         .collection("messages")
//         .add(msg);
//
//     _controller.clear();
//     _scrollToBottom();
//   }
//
//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent + 80,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
//     final time = data['timestamp'] != null
//         ? DateFormat('hh:mm a')
//         .format((data['timestamp'] as Timestamp).toDate())
//         : '';
//     final radius = const Radius.circular(12);
//     final bubbleColor = isMe ? accent.withOpacity(0.95) : Colors.grey.shade200;
//     final textColor = isMe ? Colors.white : Colors.black87;
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//         decoration: BoxDecoration(
//           color: bubbleColor,
//           borderRadius: BorderRadius.only(
//             topLeft: radius,
//             topRight: radius,
//             bottomLeft: isMe ? radius : const Radius.circular(0),
//             bottomRight: isMe ? const Radius.circular(0) : radius,
//           ),
//           boxShadow: [
//             BoxShadow(color: Colors.black12, blurRadius: 2, offset: const Offset(0, 1))
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(data['text'] ?? '', style: TextStyle(color: textColor, fontSize: 15)),
//             const SizedBox(height: 6),
//             Text(time, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMessageList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection("chats")
//           .doc(chatId)
//           .collection("messages")
//           .orderBy("timestamp", descending: false)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         final messages = snapshot.data!.docs;
//         return ListView.builder(
//           controller: _scrollController,
//           padding: const EdgeInsets.only(top: 8, bottom: 8),
//           itemCount: messages.length,
//           itemBuilder: (context, index) {
//             final data = messages[index].data() as Map<String, dynamic>;
//             final isMe = data['senderId'] == currentUserId;
//             return _buildMessageBubble(data, isMe);
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildInputBar() {
//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//         color: Colors.white,
//         child: Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.attach_file),
//               color: Colors.grey.shade700,
//               onPressed: () {},
//             ),
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(color: Colors.grey.shade200),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _controller,
//                         textCapitalization: TextCapitalization.sentences,
//                         decoration: const InputDecoration(
//                           hintText: "Write a message...",
//                           border: InputBorder.none,
//                         ),
//                         onSubmitted: (_) => _sendMessage(),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.emoji_emotions_outlined),
//                       onPressed: () {},
//                     )
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Container(
//               decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
//               child: IconButton(
//                 icon: const Icon(Icons.send, color: Colors.white),
//                 onPressed: _sendMessage,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         titleSpacing: 0,
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 18,
//               backgroundColor: Colors.grey.shade300,
//               child: const Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(widget.vendorName,
//                       style: const TextStyle(
//                           color: Colors.black87,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600)),
//                   const SizedBox(height: 2),
//                   Text("Typically replies in a few hours",
//                       style:
//                       TextStyle(color: Colors.grey.shade600, fontSize: 12)),
//                 ],
//               ),
//             ),
//             IconButton(
//               icon: Icon(Icons.call, color: accent),
//               onPressed: () {},
//             ),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(child: _buildMessageList()),
//           Divider(height: 0, color: Colors.grey.shade200),
//           _buildInputBar(),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String currentUid; // logged-in user/vendor uid
  final String otherUid;   // the other party's uid
  final String otherName;  // display name

  const ChatPage({
    Key? key,
    required this.currentUid,
    required this.otherUid,

    required this.otherName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final firestore = FirebaseFirestore.instance;
  late final String chatId;

  @override
  void initState() {
    super.initState();
    chatId = makeChatId(widget.currentUid, widget.otherUid);
    _markMessagesRead();
  }

  static String makeChatId(String a, String b) =>
      a.hashCode <= b.hashCode ? '${a}_$b' : '${b}_$a';

  Future<void> _ensureChatDocExists() async {
    final chatRef = firestore.collection('chats').doc(chatId);
    final snap = await chatRef.get();
    if (!snap.exists) {
      await chatRef.set({
        'participants': [widget.currentUid, widget.otherUid],
        'lastMessage': '',
        'lastUpdated': FieldValue.serverTimestamp(),
        'unread': {widget.currentUid: 0, widget.otherUid: 0},
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _ensureChatDocExists();

    final msgRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final data = {
      'text': text, // ✅ corrected here
      'senderId': widget.currentUid,
      'receiverId': widget.otherUid,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [widget.currentUid],
    };

    final batch = firestore.batch();
    batch.set(msgRef, data);

    // update main chat document
    final chatRef = firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
      'unread.${widget.otherUid}': FieldValue.increment(1),
    });

    await batch.commit();

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markMessagesRead() async {
    final chatRef = firestore.collection('chats').doc(chatId);
    await chatRef.set({
      'unread': {widget.currentUid: 0}
    }, SetOptions(merge: true));
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final isMe = data['senderId'] == widget.currentUid;
    final ts = data['timestamp'] as Timestamp?;
    final timeStr =
    ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Colors.pink.shade400 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              data['text'] ?? '', // ✅ message text
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              timeStr,
              style: TextStyle(
                  color:
                  (isMe ? Colors.white : Colors.black87).withOpacity(0.8),
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesQuery = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        // backgroundColor: Colors.pink,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),
              Color(0xFFFFB6C1),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: messagesQuery.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text("No messages yet."));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: docs.length,
                    itemBuilder: (context, index) =>
                        _buildMessageItem(docs[index]),
                  );
                },
              ),
            ),
            SafeArea(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.attach_file)),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.pink),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


  class _Message {
    final String text;
    final bool isMe;
    final DateTime time;
    _Message({required this.text, required this.isMe, required this.time});
  }


  // mogalnik96@gmail.com N@123,7887

