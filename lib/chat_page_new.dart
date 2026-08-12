    // import 'package:flutter/material.dart';

import 'core/core.dart';
// import 'package:intl/intl.dart';
//
// /// Example: wire this from your button:
// /// onPressed: () {
// ///   Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(vendorName: 'Moonlight Entertainments')));
// /// }
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_core/firebase_core.dart';
// //
// // class ChatPage extends StatefulWidget {
// //   final String vendorId;     // vendor unique id
// //   final String vendorName;   // vendor name
// //
// //   const ChatPage({
// //     Key? key,
// //     required this.vendorId,
// //     required this.vendorName,
// //   }) : super(key: key);
// //
// //   @override
// //   State<ChatPage> createState() => _ChatPageState();
// // }
// //
// // class _ChatPageState extends State<ChatPage> {
// //   final TextEditingController _controller = TextEditingController();
// //   final ScrollController _scrollController = ScrollController();
// //   final Color accent = const Color(0xFFE91E63);
// //
// //   String currentUserId = "user_123"; // you can replace this with your logged-in user id
// //
// //   /// Collection path: chats/{chatId}/messages/{message}
// //   /// chatId is generated using both ids (user_vendor)
// //   String get chatId =>
// //       currentUserId.hashCode <= widget.vendorId.hashCode
// //           ? '${currentUserId}_${widget.vendorId}'
// //           : '${widget.vendorId}_${currentUserId}';
// //
// //   void _sendMessage() async {
// //     final text = _controller.text.trim();
// //     if (text.isEmpty) return;
// //
// //     final msg = {
// //       "text": text,
// //       "senderId": currentUserId,
// //       "timestamp": FieldValue.serverTimestamp(),
// //     };
// //
// //     await FirebaseFirestore.instance
// //         .collection("chats")
// //         .doc(chatId)
// //         .collection("messages")
// //         .add(msg);
// //
// //     _controller.clear();
// //     _scrollToBottom();
// //   }
// //
// //   void _scrollToBottom() {
// //     Future.delayed(const Duration(milliseconds: 300), () {
// //       if (_scrollController.hasClients) {
// //         _scrollController.animateTo(
// //           _scrollController.position.maxScrollExtent + 80,
// //           duration: const Duration(milliseconds: 300),
// //           curve: Curves.easeOut,
// //         );
// //       }
// //     });
// //   }
// //
// //   Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
// //     final time = data['timestamp'] != null
// //         ? DateFormat('hh:mm a')
// //         .format((data['timestamp'] as Timestamp).toDate())
// //         : '';
// //     final radius = const Radius.circular(12);
// //     final bubbleColor = isMe ? accent.withValues(alpha: 0.95) : Colors.grey.shade200;
// //     final textColor = isMe ? Colors.white : Colors.black87;
// //
// //     return Container(
// //       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
// //       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
// //         decoration: BoxDecoration(
// //           color: bubbleColor,
// //           borderRadius: BorderRadius.only(
// //             topLeft: radius,
// //             topRight: radius,
// //             bottomLeft: isMe ? radius : const Radius.circular(0),
// //             bottomRight: isMe ? const Radius.circular(0) : radius,
// //           ),
// //           boxShadow: [
// //             BoxShadow(color: Colors.black12, blurRadius: 2, offset: const Offset(0, 1))
// //           ],
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.end,
// //           children: [
// //             Text(data['text'] ?? '', style: TextStyle(color: textColor, fontSize: 15)),
// //             const SizedBox(height: 6),
// //             Text(time, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 11)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildMessageList() {
// //     return StreamBuilder<QuerySnapshot>(
// //       stream: FirebaseFirestore.instance
// //           .collection("chats")
// //           .doc(chatId)
// //           .collection("messages")
// //           .orderBy("timestamp", descending: false)
// //           .snapshots(),
// //       builder: (context, snapshot) {
// //         if (!snapshot.hasData) {
// //           return const Center(child: CircularProgressIndicator());
// //         }
// //         final messages = snapshot.data!.docs;
// //         return ListView.builder(
// //           controller: _scrollController,
// //           padding: const EdgeInsets.only(top: 8, bottom: 8),
// //           itemCount: messages.length,
// //           itemBuilder: (context, index) {
// //             final data = messages[index].data() as Map<String, dynamic>;
// //             final isMe = data['senderId'] == currentUserId;
// //             return _buildMessageBubble(data, isMe);
// //           },
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildInputBar() {
// //     return SafeArea(
// //       top: false,
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
// //         color: Colors.white,
// //         child: Row(
// //           children: [
// //             IconButton(
// //               icon: const Icon(Icons.attach_file),
// //               color: Colors.grey.shade700,
// //               onPressed: () {},
// //             ),
// //             Expanded(
// //               child: Container(
// //                 padding: const EdgeInsets.symmetric(horizontal: 12),
// //                 decoration: BoxDecoration(
// //                   color: Colors.grey.shade100,
// //                   borderRadius: BorderRadius.circular(24),
// //                   border: Border.all(color: Colors.grey.shade200),
// //                 ),
// //                 child: Row(
// //                   children: [
// //                     Expanded(
// //                       child: TextField(
// //                         controller: _controller,
// //                         textCapitalization: TextCapitalization.sentences,
// //                         decoration: const InputDecoration(
// //                           hintText: "Write a message...",
// //                           border: InputBorder.none,
// //                         ),
// //                         onSubmitted: (_) => _sendMessage(),
// //                       ),
// //                     ),
// //                     IconButton(
// //                       icon: const Icon(Icons.emoji_emotions_outlined),
// //                       onPressed: () {},
// //                     )
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(width: 8),
// //             Container(
// //               decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
// //               child: IconButton(
// //                 icon: const Icon(Icons.send, color: Colors.white),
// //                 onPressed: _sendMessage,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 1,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: Colors.black87),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         titleSpacing: 0,
// //         title: Row(
// //           children: [
// //             CircleAvatar(
// //               radius: 18,
// //               backgroundColor: Colors.grey.shade300,
// //               child: const Icon(Icons.person, color: Colors.white),
// //             ),
// //             const SizedBox(width: 12),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(widget.vendorName,
// //                       style: const TextStyle(
// //                           color: Colors.black87,
// //                           fontSize: 16,
// //                           fontWeight: FontWeight.w600)),
// //                   const SizedBox(height: 2),
// //                   Text("Typically replies in a few hours",
// //                       style:
// //                       TextStyle(color: Colors.grey.shade600, fontSize: 12)),
// //                 ],
// //               ),
// //             ),
// //             IconButton(
// //               icon: Icon(Icons.call, color: accent),
// //               onPressed: () {},
// //             ),
// //           ],
// //         ),
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(child: _buildMessageList()),
// //           Divider(height: 0, color: Colors.grey.shade200),
// //           _buildInputBar(),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
//
// class ChatPage extends StatefulWidget {
//   final String currentUid; // logged-in user/vendor uid
//   final String otherUid;   // the other party's uid
//   final String otherName;  // display name
//
//   const ChatPage({
//     Key? key,
//     required this.currentUid,
//     required this.otherUid,
//
//     required this.otherName,
//   }) : super(key: key);
//
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final firestore = FirebaseFirestore.instance;
//   late final String chatId;
//
//   @override
//   void initState() {
//     super.initState();
//     chatId = makeChatId(widget.currentUid, widget.otherUid);
//     _markMessagesRead();
//   }
//
//   static String makeChatId(String a, String b) =>
//       a.hashCode <= b.hashCode ? '${a}_$b' : '${b}_$a';
//
//   Future<void> _ensureChatDocExists() async {
//     final chatRef = firestore.collection('chats').doc(chatId);
//     final snap = await chatRef.get();
//     if (!snap.exists) {
//       await chatRef.set({
//         'participants': [widget.currentUid, widget.otherUid],
//         'lastMessage': '',
//         'lastUpdated': FieldValue.serverTimestamp(),
//         'unread': {widget.currentUid: 0, widget.otherUid: 0},
//       });
//     }
//   }
//
//   Future<void> _sendMessage() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;
//
//     await _ensureChatDocExists();
//
//     final msgRef = firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .doc();
//
//     final data = {
//       'text': text, // ✅ corrected here
//       'senderId': widget.currentUid,
//       'receiverId': widget.otherUid,
//       'timestamp': FieldValue.serverTimestamp(),
//       'readBy': [widget.currentUid],
//     };
//
//     final batch = firestore.batch();
//     batch.set(msgRef, data);
//
//     // update main chat document
//     final chatRef = firestore.collection('chats').doc(chatId);
//     batch.update(chatRef, {
//       'lastMessage': text,
//       'lastUpdated': FieldValue.serverTimestamp(),
//       'unread.${widget.otherUid}': FieldValue.increment(1),
//     });
//
//     await batch.commit();
//
//     _controller.clear();
//     _scrollToBottom();
//   }
//
//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 250), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent + 80,
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   Future<void> _markMessagesRead() async {
//     final chatRef = firestore.collection('chats').doc(chatId);
//     await chatRef.set({
//       'unread': {widget.currentUid: 0}
//     }, SetOptions(merge: true));
//   }
//
//   Widget _buildMessageItem(DocumentSnapshot doc) {
//     final data = doc.data()! as Map<String, dynamic>;
//     final isMe = data['senderId'] == widget.currentUid;
//     final ts = data['timestamp'] as Timestamp?;
//     final timeStr =
//     ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : '';
//
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.pink.shade400 : Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(
//               data['text'] ?? '', // ✅ message text
//               style: TextStyle(
//                   color: isMe ? Colors.white : Colors.black87, fontSize: 15),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               timeStr,
//               style: TextStyle(
//                   color:
//                   (isMe ? Colors.white : Colors.black87).withValues(alpha: 0.8),
//                   fontSize: 11),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final messagesQuery = firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .orderBy('timestamp', descending: false);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.otherName),
//         // backgroundColor: Colors.pink,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4),
//               Color(0xFFFFB6C1),
//               Colors.white,
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: messagesQuery.snapshots(),
//                 builder: (context, snap) {
//                   if (!snap.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//
//                   final docs = snap.data!.docs;
//
//                   if (docs.isEmpty) {
//                     return const Center(child: Text("No messages yet."));
//                   }
//
//                   return ListView.builder(
//                     controller: _scrollController,
//                     itemCount: docs.length,
//                     itemBuilder: (context, index) =>
//                         _buildMessageItem(docs[index]),
//                   );
//                 },
//               ),
//             ),
//             SafeArea(
//               child: Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                 color: Colors.white,
//                 child: Row(
//                   children: [
//                     IconButton(
//                         onPressed: () {},
//                         icon: const Icon(Icons.attach_file)),
//                     Expanded(
//                       child: TextField(
//                         controller: _controller,
//                         decoration: const InputDecoration(
//                           hintText: 'Type a message',
//                           border: InputBorder.none,
//                         ),
//                         onSubmitted: (_) => _sendMessage(),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.send, color: Colors.pink),
//                       onPressed: _sendMessage,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//   class _Message {
//     final String text;
//     final bool isMe;
//     final DateTime time;
//     _Message({required this.text, required this.isMe, required this.time});
//   }
//
//
//
//   // mogalnik96@gmail.com N@123,7887
//
// ///////////////////////////////////////////////////////////////////////////
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ChatService {
//   static const String baseUrl = "https://happywedz.com/api/messages/user";
//
//   // -----------------------------------------
//   // GET HEADERS WITH CORRECT TOKEN
//   // -----------------------------------------
//   static Future<Map<String, String>> _headers() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("auth_token") ?? "";   // FIXED 🔥
//
//     print("TOKEN USED → $token");
//
//     return {
//       "Accept": "application/json",
//       "Authorization": "Bearer $token",
//     };
//   }
//
//   // -----------------------------------------
//   // 1️⃣ CREATE OR GET CONVERSATION
//   // -----------------------------------------
//   static Future<int?> createOrGetConversation({
//     required int vendorId,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getInt("user_id");
//
//     final url = Uri.parse("$baseUrl/conversations");
//
//     final response = await http.post(
//       url,
//       headers: await _headers(),
//       body: {
//         "vendorId": vendorId.toString(),
//         "userId": userId.toString(),
//       },
//     );
//
//     print("STATUS CODE → ${response.statusCode}");
//     print("Conversation Response RAW → ${response.body}");
//
//     // Accept ALL valid status codes 2xx
//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       print("❌ Invalid status → ${response.statusCode}");
//       return null;
//     }
//
//     final js = jsonDecode(response.body);
//     print("Conversation Response DECODED → $js");
//
//     // Normal response → { "id": 5, ... }
//     if (js["id"] != null) {
//       print("✅ Conversation ID found → ${js["id"]}");
//       return js["id"];
//     }
//
//     // Sometimes wrapped → { "conversation": { "id": 5 } }
//     if (js["conversation"]?["id"] != null) {
//       print("✅ Conversation ID found in conversation → ${js["conversation"]["id"]}");
//       return js["conversation"]["id"];
//     }
//
//     // Sometimes API returns → { "data": { "conversation": { "id": 5 } } }
//     if (js["data"]?["conversation"]?["id"] != null) {
//       print("✅ Conversation ID found in data.conversation → ${js["data"]["conversation"]["id"]}");
//       return js["data"]["conversation"]["id"];
//     }
//
//     print("❌ Conversation ID not found in JSON structure");
//     return null;
//   }
//
//
//   // -----------------------------------------
//   // 2️⃣ FETCH MESSAGES
//   // -----------------------------------------
//   static Future<List<dynamic>> fetchMessages(int conversationId) async {
//     final url = Uri.parse("$baseUrl/conversations/$conversationId/messages");
//
//     final res = await http.get(url, headers: await _headers());
//
//     print("STATUS → ${res.statusCode}");
//     print("MESSAGES RAW → ${res.body}");
//
//     if (res.statusCode < 200 || res.statusCode > 299) return [];
//
//     final js = jsonDecode(res.body);
//
//     // Case A: API returns a LIST directly
//     if (js is List) return js;
//
//     // Case B: { messages: [] }
//     if (js["messages"] is List) return js["messages"];
//
//     // Case C: { data: [] }
//     if (js["data"] is List) return js["data"];
//
//     // Case D: No messages
//     return [];
//   }
//
//   // -----------------------------------------
//   // 3️⃣ SEND MESSAGE
//   // -----------------------------------------
//   static Future<bool> sendMessage({
//     required int conversationId,
//     required int senderId,
//     required int receiverId,
//     required String message,
//   }) async {
//     final url = Uri.parse(
//       "$baseUrl/conversations/$conversationId/messages",
//     );
//
//     final res = await http.post(
//       url,
//       headers: await _headers(),
//       body: {
//         "senderId": senderId.toString(),
//         "receiverId": receiverId.toString(),
//         "senderType": "user",
//         "receiverType": "vendor",
//         "message": message,
//       },
//     );
//
//     print("Send Msg API → ${res.body}");
//
//     return res.statusCode == 200;
//   }
//
//   static Future<bool> sendPricingRequest({
//     required int vendorId,
//     required String firstName,
//     required String lastName,
//     required String email,
//     required String phone,
//     required String eventDate,
//     required String message,
//   }) async {
//     final url = Uri.parse("https://happywedz.com/request-pricing");
//
//     final res = await http.post(
//       url,
//       headers: {
//         "Accept": "application/json",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({
//         "vendorId": vendorId,
//         "firstName": firstName,
//         "lastName": lastName,
//         "email": email,
//         "phone": phone,
//         "eventDate": eventDate,
//         "message": message,
//       }),
//     );
//
//     print("PRICING REQUEST → ${res.body}");
//
//     return res.statusCode == 200 || res.statusCode == 201;
//   }
// }
//
// class ChatPage extends StatefulWidget {
//   final int currentUid;
//   final int otherUid;
//   final String otherName;
//   final int vendorId;
//
//   const ChatPage({
//     super.key,
//     required this.currentUid,
//     required this.otherUid,
//     required this.otherName,
//     required this.vendorId,
//   });
//
//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }
//
// class _ChatPageState extends State<ChatPage> {
//   final TextEditingController controller = TextEditingController();
//   final ScrollController scroll = ScrollController();
//
//   List messages = [];
//   int? conversationId;
//   Timer? timer;
//
//   @override
//   void initState() {
//     super.initState();
//     initChat();
//   }
//
//   // INITIAL CHAT SETUP
//   Future<void> initChat() async {
//     print("🔄 initChat() started...");
//
//     conversationId = await ChatService.createOrGetConversation(
//       vendorId: widget.vendorId,
//     );
//
//     if (conversationId == null) {
//       print("❌ No conversation ID!");
//       return;
//     }
//
//     print("✅ Conversation ID = $conversationId");
//
//     await fetchMessages();
//
//     timer = Timer.periodic(const Duration(seconds: 2), (_) {
//       fetchMessages();
//     });
//   }
//
//   // FETCH MESSAGES + FIRST TIME LOGIC
//   Future<void> fetchMessages() async {
//     print("🔄 FETCHING MESSAGES...");
//
//     if (conversationId == null) return;
//
//     final msg = await ChatService.fetchMessages(conversationId!);
//
//     // ⭐ FIRST TIME CHAT — NO OLD MESSAGES
//     if (messages.isEmpty && msg.isEmpty) {
//       print("✨ FIRST TIME CHAT FOR THIS USER");
//
//       await sendFirstTimePricingRequest();
//     }
//
//     setState(() => messages = msg);
//
//     Future.delayed(const Duration(milliseconds: 200), () {
//       if (scroll.hasClients) {
//         scroll.jumpTo(scroll.position.maxScrollExtent);
//       }
//     });
//   }
//
//   // FIRST TIME PRICING REQUEST + TEMPLATE MESSAGE
//   Future<void> sendFirstTimePricingRequest() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final fullName = prefs.getString("user_name") ?? "";
//     final email = prefs.getString("user_email") ?? "";
//     final phone = prefs.getString("user_phone") ?? "";
//
//     final firstName = fullName.split(" ").first;
//     final lastName = fullName.split(" ").length > 1
//         ? fullName.split(" ").last
//         : "";
//
//     print("📩 Sending Pricing Request for FIRST TIME user");
//
//     await ChatService.sendPricingRequest(
//       vendorId: widget.vendorId,
//       firstName: firstName,
//       lastName: lastName,
//       email: email,
//       phone: phone,
//       eventDate: "2025-12-01", // you can make dynamic
//       message:
//       "Customer is initiating chat for pricing & availability request.",
//     );
//
//     // SEND Auto Template Message
//     final template =
//         "Hi ${widget.otherName}, I'm interested in booking your services for my event. Could you confirm availability and share a quotation?";
//
//     await ChatService.sendMessage(
//       conversationId: conversationId!,
//       senderId: widget.currentUid,
//       receiverId: widget.otherUid,
//       message: template,
//     );
//   }
//
//   // SEND NORMAL MESSAGE
//   Future<void> sendMsg() async {
//     final text = controller.text.trim();
//     if (text.isEmpty) return;
//
//     controller.clear();
//
//     print("➡ Sending user message: $text");
//
//     await ChatService.sendMessage(
//       conversationId: conversationId!,
//       senderId: widget.currentUid,
//       receiverId: widget.otherUid,
//       message: text,
//     );
//
//     fetchMessages();
//   }
//
//   @override
//   void dispose() {
//     timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.otherName),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               controller: scroll,
//               itemCount: messages.length,
//               itemBuilder: (context, i) {
//                 final msg = messages[i];
//                 final isMe = msg["senderId"] == widget.currentUid;
//
//                 final time = DateFormat("hh:mm a")
//                     .format(DateTime.parse(msg["createdAt"]));
//
//                 return Align(
//                   alignment: isMe
//                       ? Alignment.centerRight
//                       : Alignment.centerLeft,
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     margin: const EdgeInsets.symmetric(
//                         vertical: 6, horizontal: 12),
//                     decoration: BoxDecoration(
//                       color: isMe
//                           ? Colors.pink
//                           : Colors.grey.shade200,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           msg["message"],
//                           style: TextStyle(
//                             color: isMe
//                                 ? Colors.white
//                                 : Colors.black,
//                           ),
//                         ),
//                         SizedBox(height: 5),
//                         Text(
//                           time,
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: isMe
//                                 ? Colors.white70
//                                 : Colors.black54,
//                           ),
//                         )
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           // INPUT FIELD
//           SafeArea(
//             child: Container(
//               padding: EdgeInsets.all(8),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: controller,
//                       decoration: InputDecoration(
//                           hintText: "Type a message...",
//                           border: InputBorder.none),
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.send, color: Colors.pink),
//                     onPressed: sendMsg,
//                   )
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:happy_wedz/profile.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------
// ChatService (all APIs)
// ---------------------------
class ChatService {
  static const String baseUrl = "https://happywedz.com/api/messages/user";

  // --------------------------
  // 🔐 GET TOKEN HEADER
  // --------------------------
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token") ?? "";

    print("🔐 TOKEN USED → $token");

    return {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // --------------------------
  // 1️⃣ CREATE / GET CONVERSATION
  // --------------------------
  static Future<int?> createOrGetConversation({
    required int vendorId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");

    final url = Uri.parse("$baseUrl/conversations");

    print("➡ POST CreateConversation: $url");

    final response = await http.post(
      url,
      headers: await _headers(),
      body: {
        "vendorId": vendorId.toString(),
        "userId": userId.toString(),
      },
    );

    print("⬅ STATUS CODE → ${response.statusCode}");
    print("⬅ RAW → ${response.body}");

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print("❌ Failed to create conversation");
      return null;
    }

    final js = jsonDecode(response.body);

    if (js["id"] != null) return js["id"];
    if (js["conversation"]?["id"] != null) return js["conversation"]["id"];
    if (js["data"]?["conversation"]?["id"] != null) {
      return js["data"]["conversation"]["id"];
    }

    print("❌ Conversation ID not found!");
    return null;
  }

  // --------------------------
  // 2️⃣ FETCH MESSAGES
  // --------------------------
  static Future<List<dynamic>> fetchMessages(int conversationId) async {
    final url = Uri.parse("$baseUrl/conversations/$conversationId/messages");

    print("➡ GET Messages: $url");

    final res = await http.get(url, headers: await _headers());

    print("⬅ STATUS → ${res.statusCode}");
    print("⬅ RAW MESSAGES → ${res.body}");

    if (res.statusCode != 200) return [];

    final js = jsonDecode(res.body);

    if (js is List) return js;
    if (js["messages"] is List) return js["messages"];
    if (js["data"] is List) return js["data"];

    return [];
  }

  // --------------------------
  // 3️⃣ SEND MESSAGE
  // --------------------------
  static Future<bool> sendMessage({
    required int conversationId,
    required int senderId,
    required int receiverId,
    required String message,
  }) async {
    final url =
    Uri.parse("$baseUrl/conversations/$conversationId/messages");

    print("➡ POST SendMessage: $url");
    print("   BODY: senderId=$senderId receiverId=$receiverId message=$message");

    final res = await http.post(
      url,
      headers: await _headers(),
      body: {
        "senderId": senderId.toString(),
        "receiverId": receiverId.toString(),
        "senderType": "user",
        "receiverType": "vendor",
        "message": message,
      },
    );

    print("⬅ SEND MSG RESPONSE → ${res.body}");
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // --------------------------
  // 4️⃣ PRICING REQUEST
  // --------------------------
  static Future<bool> sendPricingRequest({
    required int vendorId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String eventDate,
    required String message,
  }) async {
    final url = Uri.parse("https://happywedz.com/request-pricing");

    print("➡ POST PricingRequest: $url");
    print("   BODY: vendorId:$vendorId firstName:$firstName lastName:$lastName "
        "email:$email phone:$phone eventDate:$eventDate message:$message");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "vendorId": vendorId,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phone": phone,
        "eventDate": eventDate,
        "message": message,
      }),
    );

    print("⬅ PRICING RESPONSE → ${res.statusCode} ${res.body}");

    return res.statusCode == 200 || res.statusCode == 201;
  }
}

// ---------------------------
// ChatPage (UI + logic)
// ---------------------------
class ChatPage extends StatefulWidget {
  final int currentUid;
  final int otherUid;
  final String otherName;
  final int vendorId;

  const ChatPage({
    super.key,
    required this.currentUid,
    required this.otherUid,
    required this.otherName,
    required this.vendorId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scroll = ScrollController();

  List messages = [];
  int? conversationId;
  Timer? timer;

  bool pricingSent = false;
  bool firstTimeCheckDone = false;

  @override
  void initState() {
    super.initState();
    initChat();
  }

  //----------------------------------------------------------------------
  // PROFILE COMPLETE CHECK
  //----------------------------------------------------------------------
  Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();

    final phone = prefs.getString("user_mobile") ?? "";
    final venue = prefs.getString("wedding_venue") ?? "";
    final date = prefs.getString("wedding_date") ?? "";

    print("🔍 PROFILE CHECK → phone:$phone   venue:$venue   date:$date");

    return phone.isNotEmpty && venue.isNotEmpty && date.isNotEmpty;
  }

  //----------------------------------------------------------------------
  // SHOW POPUP IF PROFILE NOT COMPLETE
  //----------------------------------------------------------------------
  Future<void> showProfilePopup() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Complete Your Profile"),
        content: const Text(
            "To continue chatting, please complete your profile details."),
        actions: [
          TextButton(
            child: const Text("Go to Profile"),
            onPressed: () async {
              Navigator.pop(context);

              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProfileSettingsScreen()),
              );

              print("🔄 Returned from profile — restarting chat setup...");
              initChat();
            },
          )
        ],
      ),
    );
  }

  //----------------------------------------------------------------------
  // INITIAL CHAT SETUP
  //----------------------------------------------------------------------
  Future<void> initChat() async {
    print("🔄 initChat() started...");

    conversationId = await ChatService.createOrGetConversation(
      vendorId: widget.vendorId,
    );

    if (conversationId == null) {
      print("❌ No conversation ID!");
      return;
    }

    print("✅ Conversation ID = $conversationId");

    await fetchMessages();

    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      fetchMessages();
    });
  }

  //----------------------------------------------------------------------
  // FETCH MESSAGES + FIRST TIME LOGIC
  //----------------------------------------------------------------------
  Future<void> fetchMessages() async {
    if (conversationId == null) return;

    print("🔄 fetchMessages() conversationId=$conversationId");

    final result = await ChatService.fetchMessages(conversationId!);

    bool isFirstTimeChat = messages.isEmpty && result.isEmpty;

    setState(() => messages = result);

    //-------------------------------------------------------------
    // FIRST TIME CHAT → Check profile → Send pricing + template
    //-------------------------------------------------------------
    if (isFirstTimeChat && !firstTimeCheckDone) {
      firstTimeCheckDone = true;
      print("✨ First-time chat detected");

      final complete = await isProfileComplete();
      if (!complete) {
        await showProfilePopup();
        return;
      }

      if (!pricingSent) {
        await sendFirstTimePricingRequest();
      }
    }

    //-------------------------------------------------------------
    // Auto-scroll to bottom
    //-------------------------------------------------------------
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scroll.hasClients) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
      }
    });
  }

  //----------------------------------------------------------------------
  // FIRST-TIME PRICING REQUEST + TEMPLATE MESSAGE
  //----------------------------------------------------------------------
  Future<void> sendFirstTimePricingRequest() async {
    pricingSent = true;

    final prefs = await SharedPreferences.getInstance();

    final fullName = prefs.getString("user_name") ?? "";
    final email = prefs.getString("user_email") ?? "";
    final phone = prefs.getString("user_mobile") ?? "";
    final venue = prefs.getString("wedding_venue") ?? "";
    final date = prefs.getString("wedding_date") ?? "";

    final firstName = fullName.split(" ").first;
    final lastName =
    fullName.split(" ").length > 1 ? fullName.split(" ").last : "";

    print("📩 Sending FIRST-TIME pricing request...");

    await ChatService.sendPricingRequest(
      vendorId: widget.vendorId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      eventDate: date,
      message: "Looking for pricing and availability for event in $venue on $date.",
    );

    //-------------------------------------------------------------
    // PUT TEMPLATE INSIDE TEXT BOX (USER CAN EDIT + SEND)
    //-------------------------------------------------------------
    final template =
        "Hi ${widget.otherName},\n"
        "I'm planning my event in $venue on $date.\n"
        "I'm interested in your services."
        "Could you please confirm availability and share pricing details?";


    controller.text = template;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    print("⌨️ Template with line breaks loaded in typing box.");

  }

  //----------------------------------------------------------------------
  // NORMAL SEND MESSAGE
  //----------------------------------------------------------------------
  // Future<void> sendMsg() async {
  //   final text = controller.text.trim();
  //   if (text.isEmpty) return;
  //
  //   controller.clear();
  //
  //   print("➡ Sending user message: $text");
  //
  //   await ChatService.sendMessage(
  //     conversationId: conversationId!,
  //     senderId: widget.currentUid,
  //     receiverId: widget.otherUid,
  //     message: text,
  //   );
  //
  //   fetchMessages();
  // }
  Future<void> sendMsg() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    // 🚫 HARD STOP if conversation not ready
    if (conversationId == null) {
      AppSnackbar.info(context, "Chat is starting, please wait...");
      return;
    }

    controller.clear();

    print("➡ Sending user message: $text");
    print("🧠 Using conversationId = $conversationId");

    await ChatService.sendMessage(
      conversationId: conversationId!, // SAFE NOW
      senderId: widget.currentUid,
      receiverId: widget.otherUid,
      message: text,
    );

    fetchMessages();
  }

  //----------------------------------------------------------------------
  // UI STARTS HERE
  //----------------------------------------------------------------------
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
      ),
      body: Column(
        children: [
          //-------------------------------------------------------
          // CHAT LIST
          //-------------------------------------------------------
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isMe = msg["senderId"] == widget.currentUid;

                final time = DateFormat("hh:mm a")
                    .format(DateTime.parse(msg["createdAt"]));

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.pink : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg["message"],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                            isMe ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          //-------------------------------------------------------
          // MESSAGE INPUT BOX
          //-------------------------------------------------------
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,       // you can increase if needed
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type a message...",
                      ),
                    )

                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: sendMsg,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


