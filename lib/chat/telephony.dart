// import 'package:telephony/telephony.dart';
//
//
//
//
//
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'chat_service.dart';
//
// /// Call this function whenever an SMS reply is received
// Future<void> updateReplyInDatabase(String senderPhone, String text) async {
//   final chatService = ChatService();
//
//   // Map sender phone to userId
//   final otherUserId = await chatService.getUserIdFromPhone(senderPhone);
//   if (otherUserId == null) return; // no user found for this phone
//
//   // Get or create chat
//   final chatId = await chatService.createOrGetChat(otherUserId);
//
//   final chatDoc = FirebaseFirestore.instance.collection("chats").doc(chatId);
//
//   // Update last message and timestamp
//   await chatDoc.update({
//     "lastMessage": text,
//     "lastMessageTime": FieldValue.serverTimestamp(),
//   });
//
//   // Store each message separately
//   await chatDoc.collection("messages").add({
//     "senderId": otherUserId,
//     "text": text,
//     "timestamp": FieldValue.serverTimestamp(),
//     "seen": false,
//   });
// }
//
// final telephony = Telephony.instance;
//
// void listenIncomingSms() async {
//   final bool? granted = await telephony.requestSmsPermissions;
//   if (!(granted ?? false)) return;
//
//   telephony.listenIncomingSms(
//     onNewMessage: (SmsMessage message) {
//       print("Received SMS from ${message.address}: ${message.body}");
//
//       // Update your Firestore database with reply
//       updateReplyInDatabase(
//         message.address ?? '',
//         message.body ?? '',
//       );
//     },
//     listenInBackground: true,
//   );
// }
