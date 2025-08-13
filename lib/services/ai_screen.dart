import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../secret.dart';

// class AiChatScreen extends StatefulWidget {
//   const AiChatScreen({super.key});
//
//   @override
//   State<AiChatScreen> createState() => _AiChatScreenState();
// }
//
// class _AiChatScreenState extends State<AiChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final List<Map<String, String>> _messages = [];
//   late GenerativeModel _model;
//   late ChatSession _chat;
//
//   @override
//   void initState() {
//     super.initState();
//     _model = GenerativeModel(model: 'gemini-pro', apiKey: geminiApiKey);
//     _chat = _model.startChat();
//
//   }
//
//   Future<void> _sendMessage() async {
//     String message = _controller.text.trim();
//     if (message.isEmpty) return;
//
//     setState(() {
//       _messages.add({"sender": "user", "text": message});
//       _controller.clear();
//     });
//
//     try {
//       final response = await _chat.sendMessage(Content.text(message));
//       print("Gemini says: ${response.text}");
//       final reply = response.text ?? "I didn't understand that.";
//       setState(() {
//         _messages.add({"sender": "ai", "text": reply});
//       });
//     } catch (e) {
//       print("⚠️ Gemini Error: $e");
//       setState(() {
//         _messages.add({
//           "sender": "ai",
//           "text": "⚠️ Failed to get response. Check your API key or internet."
//         });
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("AI Assistant"),
//         backgroundColor: Colors.black,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final msg = _messages[index];
//                 final isUser = msg["sender"] == "user";
//                 return Align(
//                   alignment:
//                   isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 4),
//                     padding: const EdgeInsets.all(12),
//                     constraints: BoxConstraints(
//                         maxWidth: MediaQuery.of(context).size.width * 0.75),
//                     decoration: BoxDecoration(
//                       color: isUser ? Colors.pink[100] : Colors.grey[200],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(msg["text"] ?? '',
//                         style: const TextStyle(color: Colors.black87)),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const Divider(height: 1),
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     onSubmitted: (_) => _sendMessage(),
//                     decoration: const InputDecoration(
//                       hintText: "Ask anything about your wedding...",
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _sendMessage,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.black,
//                   ),
//                   child: const Text("Send"),
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  _AiChatScreenState createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  late GenerativeModel _model;
  late ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
    _chat = _model.startChat();
  }

  Future<void> _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": message});
      _controller.clear();
    });

    try {
      final response = await _chat.sendMessage(Content.text(message));
      final reply = response.text ?? "I didn't understand that.";
      setState(() {
        _messages.add({"sender": "ai", "text": reply});
      });
    } catch (e) {
      print("Gemini Error: $e");
      setState(() {
        _messages.add({
          "sender": "ai",
          "text": "⚠️ Failed to get response. Check your API key or internet."
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gemini Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.pink[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(msg["text"] ?? ''),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Ask anything...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: Text("Send"),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
