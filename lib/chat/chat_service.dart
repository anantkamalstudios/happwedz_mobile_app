import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  Future<void> vendorReply(String chatId, String vendorId, String replyText) async {
    final chatDoc = _firestore.collection('chats').doc(chatId);

    // Add message to messages subcollection
    await chatDoc.collection('messages').add({
      'senderId': vendorId,
      'text': replyText,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });

    // Update lastMessage and lastMessageTime
    await chatDoc.update({
      'lastMessage': replyText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> getUserIdFromPhone(String phone) async {
    final snapshot = await _firestore
        .collection("users")
        .where("phone", isEqualTo: phone)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }

  Future<String> createOrGetChat(String otherUserId) async {
    final chatsQuery = await _firestore
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .get();

    for (var doc in chatsQuery.docs) {
      final users = List<String>.from(doc['users']);
      if (users.contains(otherUserId)) {
        return doc.id;
      }
    }

    final chatDoc = await _firestore.collection('chats').add({
      'users': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return chatDoc.id;
  }

  /// Send message with optional reply
  Future<void> sendMessage(
      String chatId,
      String text, {
        String? imageUrl,
        String? replyToMessageId,
        String? replyToText,
      }) async {
    final messageId = const Uuid().v4();
    final timestamp = FieldValue.serverTimestamp();

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'senderId': currentUserId,
      'text': text,
      'imageUrl': imageUrl ?? '',
      'timestamp': timestamp,
      'seen': false,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': timestamp,
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markMessagesSeen(String chatId) async {
    try {
      final unseenMessagesQuery = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('seen', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUserId)
          .orderBy('senderId')
          .orderBy(FieldPath.documentId)
          .limit(50);

      final snapshot = await unseenMessagesQuery.get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'seen': true});
      }
    } catch (e) {
      print('⚠️ Failed to mark messages seen: $e');
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['seen'] == false && data['senderId'] != currentUserId) {
          await doc.reference.update({'seen': true});
        }
      }
    }
  }
}



// class ChatService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   String get currentUserId => _auth.currentUser!.uid;
//   Future<String?> getUserIdFromPhone(String phone) async {
//     final snapshot = await _firestore
//         .collection("users")
//         .where("phone", isEqualTo: phone)
//         .get();
//
//     if (snapshot.docs.isNotEmpty) {
//       return snapshot.docs.first.id;
//     }
//     return null; // phone not found
//   }
//
//
//   /// Create or get chat between two users
//   Future<String> createOrGetChat(String otherUserId) async {
//     final chatsQuery = await _firestore
//         .collection('chats')
//         .where('users', arrayContains: currentUserId)
//         .get();
//
//     for (var doc in chatsQuery.docs) {
//       final users = List<String>.from(doc['users']);
//       if (users.contains(otherUserId)) {
//         return doc.id; // existing chat
//       }
//     }
//
//     // create new chat
//     final chatDoc = await _firestore.collection('chats').add({
//       'users': [currentUserId, otherUserId],
//       'lastMessage': '',
//       'lastMessageTime': FieldValue.serverTimestamp(),
//     });
//
//     return chatDoc.id;
//   }
//
//   /// Send message
//   Future<void> sendMessage(String chatId, String text,
//       {String? imageUrl}) async {
//     final messageId = const Uuid().v4();
//     final timestamp = FieldValue.serverTimestamp();
//
//     await _firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .doc(messageId)
//         .set({
//       'senderId': currentUserId,
//       'text': text,
//       'imageUrl': imageUrl ?? '',
//       'timestamp': timestamp,
//       'seen': false,
//     });
//
//     // update last message
//     await _firestore.collection('chats').doc(chatId).update({
//       'lastMessage': text,
//       'lastMessageTime': timestamp,
//     });
//   }
//
//   /// Stream messages
//   Stream<QuerySnapshot> getMessages(String chatId) {
//     return _firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .orderBy('timestamp', descending: true)
//         .snapshots();
//   }
//
//   /// Mark messages as seen safely (index-safe)
//   Future<void> markMessagesSeen(String chatId) async {
//     try {
//       final unseenMessagesQuery = _firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .where('seen', isEqualTo: false)
//           .where('senderId', isNotEqualTo: currentUserId)
//           .orderBy('senderId')           // required for composite index
//           .orderBy(FieldPath.documentId) // required for composite index
//           .limit(50);                     // optional limit for batch update
//
//       final snapshot = await unseenMessagesQuery.get();
//
//       for (var doc in snapshot.docs) {
//         await doc.reference.update({'seen': true});
//       }
//     } catch (e) {
//       print('⚠️ Failed to mark messages seen: $e');
//       // Optional fallback: filter manually if index not ready
//       final snapshot = await _firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .get();
//
//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         if (data['seen'] == false && data['senderId'] != currentUserId) {
//           await doc.reference.update({'seen': true});
//         }
//       }
//     }
//   }
// }
