import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'chat_screen.dart';
class ChatListScreen extends StatelessWidget {
  final ChatService _chatService = ChatService();

  ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: _chatService.currentUserId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chats = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final users = List<String>.from(chat['users']);
              final otherUserId = users.firstWhere((id) => id != _chatService.currentUserId);
              final lastMessage = chat['lastMessage'] ?? '';
              return ListTile(
                title: Text(otherUserId),
                subtitle: Text(lastMessage),
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        otherUserName: otherUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// class ChatListScreen extends StatelessWidget {
//   final ChatService _chatService = ChatService();
//
//   ChatListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Chats')),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('chats')
//             .where('users', arrayContains: _chatService.currentUserId)
//             .orderBy('lastMessageTime', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//           final chats = snapshot.data!.docs;
//           return ListView.builder(
//             itemCount: chats.length,
//             itemBuilder: (context, index) {
//               final chat = chats[index];
//               final users = List<String>.from(chat['users']);
//               final otherUserId = users.firstWhere((id) => id != _chatService.currentUserId);
//               final lastMessage = chat['lastMessage'] ?? '';
//               return ListTile(
//                 title: Text(otherUserId), // Replace with actual name from users collection
//                 subtitle: Text(lastMessage),
//                 onTap: () async {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ChatScreen(
//                         chatId: chat.id,
//                         otherUserName: otherUserId,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
