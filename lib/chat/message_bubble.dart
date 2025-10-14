import 'package:flutter/material.dart';
class MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final bool isMe;
  final String? imageUrl;
  final bool seen;
  final String? replyToText;
  final VoidCallback onReply;

  const MessageBubble({
    super.key,
    required this.messageId,
    required this.text,
    required this.isMe,
    this.imageUrl,
    this.seen = false,
    this.replyToText,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onReply,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.pink[300] : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Show replied message if exists
                if (replyToText != null && replyToText!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.pink[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isMe ? Colors.pink[700]! : Colors.grey[700]!,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      replyToText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.pink[900] : Colors.grey[900],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Main message content
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl!),
                  )
                else
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),

                // Seen status
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      seen ? Icons.done_all : Icons.check,
                      size: 14,
                      color: seen ? Colors.blue : Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// class MessageBubble extends StatelessWidget {
//   final String text;
//   final bool isMe;
//   final String? imageUrl;
//   final bool seen;
//
//   const MessageBubble({
//     super.key,
//     required this.text,
//     required this.isMe,
//     this.imageUrl,
//     this.seen = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: ConstrainedBox(
//         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: isMe ? Colors.pink[300] : Colors.grey[300],
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(16),
//               topRight: const Radius.circular(16),
//               bottomLeft: Radius.circular(isMe ? 16 : 0),
//               bottomRight: Radius.circular(isMe ? 0 : 16),
//             ),
//           ),
//           child: imageUrl != null && imageUrl!.isNotEmpty
//               ? Image.network(imageUrl!)
//               : Column(
//             crossAxisAlignment:
//             isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             children: [
//               Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
//               if (isMe)
//                 Icon(
//                   seen ? Icons.done_all : Icons.check,
//                   size: 12,
//                   color: seen ? Colors.blue : Colors.white70,
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
