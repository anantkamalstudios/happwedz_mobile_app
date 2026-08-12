
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;





/// A self-contained, single-file Chat screen inspired by ChatGPT for the
/// HappyWedz AI backend. It handles:
/// - Sending messages to /api/user_chat
/// - Updating & persisting session_id
/// - Fetching chat history from /api/chat_history?session_id=...
/// - Showing vendor results as cards when `results` arrives
/// - New chat (start fresh) feature
/// - Local chat history caching (SharedPreferences) for quick access
///
/// NOTE: Add `http` and `shared_preferences` to pubspec.yaml dependencies.

const String kBaseUrl = 'http://shaadiai.happywedz.com';

class GenieScreen extends StatefulWidget {
  const GenieScreen({super.key});

  @override
  State<GenieScreen> createState() => _GenieScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final List<dynamic>? results; // If backend returns vendor results

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? createdAt,
    this.results,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'createdAt': createdAt.toIso8601String(),
    'results': results,
  };

  static ChatMessage fromJson(Map<String, dynamic> j) => ChatMessage(
    text: j['text'] as String? ?? '',
    isUser: j['isUser'] as bool? ?? false,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    results: j['results'] as List<dynamic>?,
  );
}

class ApiService {
  final http.Client client;
  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required int? userId,
    required String query,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/user_chat');
    final body = jsonEncode({
      'session_id': sessionId,
      'user_query': query,
      'user_id': userId,
    });

    final res = await client.post(uri,
        headers: {"Content-Type": "application/json"}, body: body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      // backend returns { data: { response: {...}, session_id: '...' } }
      return decoded;
    }

    throw Exception('API Error ${res.statusCode}: ${res.body}');
  }

  Future<List<Map<String, dynamic>>> fetchChatHistory(String sessionId) async {
    final uri = Uri.parse('$kBaseUrl/api/chat_history?session_id=$sessionId');
    final res = await client.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      final items = decoded['data'] as List<dynamic>? ?? [];
      return items.cast<Map<String, dynamic>>();
    }
    return [];
  }
}

class _GenieScreenState extends State<GenieScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _api = ApiService();

  String? sessionId;
  int? userId;
  bool isLoadingResponse = false;
  bool isFetchingHistory = false;

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // initial welcome message
    messages.add(ChatMessage(
        text: 'Hi! I am your Wedding Genie ✨\nHow can I help you today?',
        isUser: false));
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    sessionId = prefs.getString('genie_session_id');

    // If we have a session, fetch server history to sync
    if (sessionId != null) {
      await _fetchAndAppendHistory();
    }
  }

  Future<void> _persistSessionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    sessionId = id;
    await prefs.setString('genie_session_id', id);
  }

  Future<void> _persistLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMsgs = messages.map((m) => m.toJson()).toList();
    await prefs.setString('genie_local_messages', jsonEncode(jsonMsgs));
  }

  Future<List<ChatMessage>> _loadLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('genie_local_messages');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<void> _fetchAndAppendHistory() async {
    if (sessionId == null) return;
    setState(() => isFetchingHistory = true);
    try {
      final serverItems = await _api.fetchChatHistory(sessionId!);
      // serverItems is list of { content: <string|object>, role: 'user'|'assistant' }
      for (final itm in serverItems) {
        final role = (itm['role'] as String?) ?? 'assistant';
        final content = itm['content'];
        String text;
        List<dynamic>? results;

        if (content is String) {
          text = content;
        } else if (content is Map<String, dynamic>) {
          // attempt to extract summary & results
          text = content['summary'] ?? '';
          results = content['results'] as List<dynamic>?;
        } else {
          text = content.toString();
        }

        messages.add(ChatMessage(text: text, isUser: role == 'user', results: results));
      }
    } catch (_) {
      // ignore fetch errors silently
    }
    setState(() => isFetchingHistory = false);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add user message locally
    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      isLoadingResponse = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final apiResp = await _api.sendMessage(
        sessionId: sessionId ?? '',
        userId: userId,
        query: text,
      );

      // backend returns wrapper -> decoded['data']
      final data = apiResp['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Malformed response');

      // Update session id if provided
      if (data['session_id'] != null) {
        await _persistSessionId(data['session_id'] as String);
      }

      final response = data['response'] as Map<String, dynamic>?;
      final summary = response?['summary'] as String? ?? '';
      final results = response?['results'] as List<dynamic>?;

      // Append bot reply
      setState(() {
        messages.add(ChatMessage(text: summary, isUser: false, results: results));
      });

      // persist local copy
      await _persistLocalMessages();

    } catch (e) {
      setState(() {
        messages.add(ChatMessage(text: 'Server not responding. Try again later.', isUser: false));
      });
    } finally {
      setState(() => isLoadingResponse = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startNewChat() async {
    // clear session & messages and notify backend by sending an empty new session (optional)
    setState(() {
      messages = [ChatMessage(text: 'New chat started. How can I help?', isUser: false)];
      sessionId = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('genie_session_id');
    await prefs.remove('genie_local_messages');
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final name = vendor['name'] ?? 'Vendor';
    final location = vendor['location'] ?? '';
    final rating = vendor['rating'] ?? 0;
    final type = vendor['type'] ?? '';
    final why = (vendor['why_consider'] as List<dynamic>?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.pink.shade50,
                  child: Text(name.isNotEmpty ? name[0] : 'V', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('$type • $location', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Text(rating.toString()),
                  ],
                )
              ],
            ),
            if (why.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: why.map((w) => Chip(label: Text(w, style: const TextStyle(fontSize: 12)))).toList(),
              )
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {
                  // open vendor details or external link
                }, child: const Text('View')),
                ElevatedButton(onPressed: () {
                  // inquiry flow
                }, child: const Text('Enquire'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 10, left: 50, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 8)],
          ),
          child: Text(msg.text, style: const TextStyle(fontSize: 15)),
        ),
      );
    }

    // Assistant bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.pink.shade50),
            child: const Icon(Icons.auto_awesome, color: Colors.pinkAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.08), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.text, style: const TextStyle(fontSize: 15, height: 1.4)),
                  if (msg.results != null && msg.results!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // show vendor cards
                    ...msg.results!.cast<Map<String, dynamic>>().map((v) => _buildVendorCard(v)).toList(),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Wedding Genie', style: TextStyle(color: Colors.black87)),
        actions: [
          IconButton(onPressed: () async {
            // new chat
            final should = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Start new chat?'),
              content: const Text('This will clear current session and start a fresh conversation.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start'))
              ],
            ));

            if (should == true) {
              await _startNewChat();
            }

          }, icon: const Icon(Icons.add_circle_outline, color: Colors.black87)),
          IconButton(onPressed: () async {
            // open chat history panel
            showModalBottomSheet(context: context, builder: (_) => _HistoryPanel(messages: messages));
          }, icon: const Icon(Icons.history, color: Colors.black87)),
        ],
      ),
      body: Column(
        children: [
          if (isFetchingHistory) LinearProgressIndicator(minHeight: 3, color: Colors.pinkAccent),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (context, i) => _buildMessageBubble(messages[i]),
            ),
          ),

          // input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.pinkAccent)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.white, border: Border.all(color: Colors.pink.shade50)),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            decoration: const InputDecoration.collapsed(hintText: 'Ask me about venues, planners, decorators...'),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        if (isLoadingResponse) const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.pinkAccent,
                    child: IconButton(onPressed: () => _sendMessage(), icon: const Icon(Icons.send, color: Colors.white)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final List<ChatMessage> messages;
  const _HistoryPanel({required this.messages});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chat History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final m = messages[i];
                  return ListTile(
                    leading: Icon(m.isUser ? Icons.person : Icons.auto_awesome),
                    title: Text(m.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(m.createdAt.toLocal().toString()),
                    onTap: () {
                      // maybe open that message in chat — for now just close
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () {
              Navigator.pop(context);
            }, child: const Text('Close'))
          ],
        ),
      ),
    );
  }
}

// class GenieScreen extends StatefulWidget {
//   const GenieScreen({super.key});
//
//   @override
//   State<GenieScreen> createState() => _GenieScreenState();
// }
//
// class _GenieScreenState extends State<GenieScreen>
//     with TickerProviderStateMixin {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//
//   String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
//   int? userId;
//   bool isLoadingResponse = false;
//
//   final List<Map<String, dynamic>> messages = [
//     {
//       'isUser': false,
//       'text':
//       "Hi! I am AI Wedding Planner ✨\nHow can I help you plan your dream wedding today?",
//     },
//   ];
//
//   /// Load user_id from SharedPreferences
//   Future<void> _loadUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     userId = prefs.getInt("user_id");
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserId();
//     _genieAnimation = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..forward();
//
//     _sendButtonController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//   }
//
//   late AnimationController _genieAnimation;
//   late AnimationController _sendButtonController;
//
//   @override
//   void dispose() {
//     _genieAnimation.dispose();
//     _sendButtonController.dispose();
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   /// API CALL FUNCTION
//   Future<Map<String, dynamic>> callChatApi(String query) async {
//     try {
//       print("🚀 Sending request to API...");
//       print("➡️ session_id: $sessionId");
//       print("➡️ user_id: $userId");
//       print("➡️ query: $query");
//
//       final res = await http.post(
//         Uri.parse("http://shaadiai.happywedz.com/api/user_chat"),
//         headers: {
//           "Content-Type": "application/json",
//           "Accept": "application/json",
//         },
//         body: jsonEncode({
//           "session_id": sessionId,
//           "user_query": query,
//           "user_id": userId,
//         }),
//       );
//
//       print("📬 STATUS CODE: ${res.statusCode}");
//       print("📩 RAW RESPONSE: ${res.body}");
//
//       final decoded = jsonDecode(res.body);
//
//       final mainData = decoded["data"];
//       final response = mainData["response"];
//
//       // UPDATE SESSION ID (VERY IMPORTANT)
//       sessionId = mainData["session_id"];
//
//       return {
//         "summary": response["summary"] ?? "No response received.",
//         "results": response["results"] ?? []
//       };
//
//     } catch (e, stack) {
//       print("🔥 API ERROR: $e");
//       print("🔥 STACK TRACE: $stack");
//
//       return {"summary": "⚠️ Server not responding. Try again later."};
//     }
//   }
//
//   /// SEND MESSAGE HANDLER
//   void _sendMessage() async {
//     if (_controller.text.trim().isEmpty) return;
//
//     final userText = _controller.text.trim();
//
//     // Add User Message
//     setState(() {
//       messages.add({'isUser': true, 'text': userText});
//       isLoadingResponse = true;
//
//       // Temporary typing message
//       messages.add({
//         'isUser': false,
//         'text': "AI wedding planner is typing… ✨",
//         "temp": true
//       });
//     });
//
//     _controller.clear();
//     _scrollToBottom();
//
//     /// API CALL
//     final apiResponse = await callChatApi(userText);
//     final botReply = apiResponse["summary"];
//
//     // Remove typing message + Add real message
//     setState(() {
//       messages.removeWhere((m) => m["temp"] == true);
//       messages.add({'isUser': false, 'text': botReply});
//       isLoadingResponse = false;
//     });
//
//     Future.delayed(const Duration(milliseconds: 200), () {
//       _scrollToBottom();
//     });
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent + 120,
//         duration: const Duration(milliseconds: 400),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(60),
//         child: FadeTransition(
//           opacity:
//           CurvedAnimation(parent: _genieAnimation, curve: Curves.easeIn),
//           child: AppBar(
//             automaticallyImplyLeading: false,
//             elevation: 0,
//             backgroundColor: Colors.white,
//             flexibleSpace: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                           color: Colors.black87),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     const Expanded(
//                       child: Text(
//                         "Ask our AI anything",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 17,
//                             color: Colors.black87),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.menu_rounded, color: Colors.black87),
//                       onPressed: () {
//                         Navigator.of(context).push(_LeftSideSheetRoute());
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF8FB), Color(0xFFFFEEF4)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 controller: _scrollController,
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 itemCount: messages.length,
//                 itemBuilder: (context, index) {
//                   final msg = messages[index];
//                   return msg['isUser']
//                       ? _buildUserBubble(msg['text'])
//                       : _buildGenieBubble(msg['text']);
//                 },
//               ),
//             ),
//             _buildBottomInputBar(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // UI BUBBLES
//   // -------------------------------------------------------------------
//
//   Widget _buildGenieBubble(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.pink.shade100, width: 1.5),
//               color: Colors.white,
//             ),
//             child: const Icon(Icons.auto_awesome,
//                 color: Colors.pinkAccent, size: 20),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(18),
//                   topRight: Radius.circular(18),
//                   bottomRight: Radius.circular(18),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.pinkAccent.withValues(alpha: 0.15),
//                     blurRadius: 12,
//                     offset: const Offset(0, 6),
//                   ),
//                 ],
//               ),
//               child: Text(text,
//                   style: const TextStyle(
//                       fontSize: 15, color: Colors.black87, height: 1.4)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildUserBubble(String text) {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Container(
//         margin: const EdgeInsets.only(top: 10, left: 50),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(18),
//             topRight: Radius.circular(18),
//             bottomLeft: Radius.circular(18),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withValues(alpha: 0.15),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Text(text,
//             style: const TextStyle(fontSize: 15, color: Colors.black87)),
//       ),
//     );
//   }
//
//   // -------------------------------------------------------------------
//   // INPUT BAR
//   // -------------------------------------------------------------------
//
//   Widget _buildBottomInputBar() {
//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Color(0x1AF06292),
//               blurRadius: 10,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFFFE6F0),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.add, color: Colors.pinkAccent),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Container(
//                 height: 44,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(22),
//                   border: Border.all(color: Colors.pink.shade50, width: 1.5),
//                 ),
//                 child: TextField(
//                   controller: _controller,
//                   style: const TextStyle(fontSize: 14),
//                   decoration: const InputDecoration(
//                     hintText: "Ask me questions...",
//                     border: InputBorder.none,
//                   ),
//                   onSubmitted: (_) => _sendMessage(),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             AnimatedBuilder(
//               animation: _sendButtonController,
//               builder: (context, child) {
//                 final sine =
//                 math.sin(_sendButtonController.value * 2 * math.pi);
//                 final normalized = ((sine + 1) / 2).clamp(0.0, 1.0);
//                 final bg = Color.lerp(const Color(0xFFFF5BA5),
//                     const Color(0xFFFF85C2), 1 - normalized)!;
//
//                 return Container(
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: bg,
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.send_rounded,
//                         color: Colors.white, size: 20),
//                     onPressed: _sendMessage,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
// // LEFT SIDE PANEL (unchanged, works same)
// class _LeftSideSheetRoute extends PageRouteBuilder {
//   _LeftSideSheetRoute()
//       : super(
//     transitionDuration: const Duration(milliseconds: 400),
//     reverseTransitionDuration: const Duration(milliseconds: 300),
//     opaque: false,
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return FadeTransition(
//         opacity: CurvedAnimation(
//             parent: animation, curve: Curves.easeInOut),
//         child: SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(-1, 0),
//             end: Offset.zero,
//           ).animate(CurvedAnimation(
//               parent: animation, curve: Curves.easeOutCubic)),
//           child: const _ChatHistoryPanel(),
//         ),
//       );
//     },
//   );
// }
//
// class _ChatHistoryPanel extends StatelessWidget {
//   const _ChatHistoryPanel({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: FractionallySizedBox(
//         widthFactor: 0.9,
//         child: Material(
//           color: Colors.white,
//           elevation: 6,
//           child: Column(
//             children: [
//               const SizedBox(height: 50),
//               const Text(
//                 "History Coming Soon...",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
























// class GenieScreen extends StatefulWidget {
//   const GenieScreen({super.key});
//
//   @override
//   State<GenieScreen> createState() => _GenieScreenState();
// }
//
// class _GenieScreenState extends State<GenieScreen>
//     with TickerProviderStateMixin {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//
//   final List<Map<String, dynamic>> messages = [
//     {
//       'isUser': false,
//       'text':
//       "Hi! I am Genie ✨\nHow can I help you plan your dream wedding today?",
//     },
//   ];
//
//   late AnimationController _genieAnimation;
//   late AnimationController _sendButtonController;
//
//   @override
//   void initState() {
//     super.initState();
//     _genieAnimation = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..forward();
//
//     _sendButtonController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//   }
//
//   @override
//   void dispose() {
//     _genieAnimation.dispose();
//     _sendButtonController.dispose();
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _sendMessage() {
//     if (_controller.text.trim().isEmpty) return;
//     final userMsg = _controller.text.trim();
//     setState(() {
//       messages.add({'isUser': true, 'text': userMsg});
//     });
//     _controller.clear();
//
//     Future.delayed(const Duration(milliseconds: 200), () {
//       _scrollToBottom();
//     });
//
//     // Simulated Genie reply
//     Future.delayed(const Duration(seconds: 1), () {
//       setState(() {
//         messages.add({
//           'isUser': false,
//           'text':
//           "That sounds absolutely magical! 🎉 Let's start planning your dream destination wedding. Could you share which destination you're considering? 😊",
//         });
//       });
//       Future.delayed(const Duration(milliseconds: 200), () {
//         _scrollToBottom();
//       });
//     });
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent + 80,
//         duration: const Duration(milliseconds: 400),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(60),
//         child: FadeTransition(
//           opacity:
//           CurvedAnimation(parent: _genieAnimation, curve: Curves.easeIn),
//           child: AppBar(
//             automaticallyImplyLeading: false,
//             elevation: 0,
//             backgroundColor: Colors.white,
//             flexibleSpace: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                           color: Colors.black87),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     const Expanded(
//                       child: Text(
//                         "Ask our AI anything",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 17,
//                             color: Colors.black87),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.menu_rounded, color: Colors.black87),
//                       onPressed: () {
//                         Navigator.of(context).push(_LeftSideSheetRoute());
//                       },
//                     ),
//
//
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF8FB), Color(0xFFFFEEF4)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 controller: _scrollController,
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 itemCount: messages.length + 1,
//                 itemBuilder: (context, index) {
//                   if (index == 1) {
//                     // Show popular questions below the first Genie message
//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           "Popular questions for you !",
//                           style: TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 15,
//                               color: Colors.black87),
//                         ),
//                         const SizedBox(height: 12),
//                         _buildSuggestionCard(
//                           title: "Budget",
//                           subtitle: "Plan my dream destination wedding",
//                           icon: Icons.arrow_forward_ios_rounded,
//                         ),
//                         const SizedBox(height: 10),
//                         _buildSuggestionCard(
//                           title: "Venues",
//                           subtitle: "Show me the best wedding venues",
//                           icon: Icons.north_east_rounded,
//                         ),
//                       ],
//                     );
//                   }
//
//                   if (index < messages.length) {
//                     final msg = messages[index];
//                     return msg['isUser']
//                         ? _buildUserBubble(msg['text'])
//                         : _buildGenieBubble(msg['text']);
//                   }
//
//                   return const SizedBox(height: 20);
//                 },
//               ),
//             ),
//             _buildBottomInputBar(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildGenieBubble(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.pink.shade100, width: 1.5),
//               color: Colors.white,
//             ),
//             child: const Icon(Icons.auto_awesome,
//                 color: Colors.pinkAccent, size: 20),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(18),
//                       topRight: Radius.circular(18),
//                       bottomRight: Radius.circular(18),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.pinkAccent.withValues(alpha: 0.15),
//                         blurRadius: 12,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: Text(
//                     text,
//                     style: const TextStyle(
//                         fontSize: 15, color: Colors.black87, height: 1.4),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 _buildGenieActions(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGenieActions() {
//     final icons = [
//       Icons.insert_drive_file_rounded,
//       Icons.share_rounded,
//       Icons.edit_rounded,
//       Icons.favorite_border_rounded,
//       Icons.location_on_rounded
//     ];
//     return Row(
//       children: icons
//           .map(
//             (icon) => Padding(
//           padding: const EdgeInsets.only(right: 6),
//           child: Container(
//             width: 30,
//             height: 30,
//             decoration: BoxDecoration(
//               color: Colors.pink.shade50,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: Colors.pinkAccent, size: 16),
//           ),
//         ),
//       )
//           .toList(),
//     );
//   }
//
//   Widget _buildUserBubble(String text) {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Container(
//         margin: const EdgeInsets.only(top: 10, left: 50),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(18),
//             topRight: Radius.circular(18),
//             bottomLeft: Radius.circular(18),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withValues(alpha: 0.15),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Text(text,
//             style: const TextStyle(fontSize: 15, color: Colors.black87)),
//       ),
//     );
//   }
//
//   Widget _buildSuggestionCard({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//   }) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           messages.add({'isUser': true, 'text': subtitle});
//         });
//         _scrollToBottom();
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.pink.shade100.withValues(alpha: 0.3),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title,
//                         style: const TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 15)),
//                     const SizedBox(height: 4),
//                     Text(subtitle,
//                         style: const TextStyle(
//                             color: Colors.black54, fontSize: 13)),
//                   ]),
//             ),
//             Icon(icon, color: Colors.pinkAccent, size: 18),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomInputBar() {
//     return SafeArea(
//       top: false,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Color(0x1AF06292),
//               blurRadius: 10,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFFFE6F0),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.add, color: Colors.pinkAccent),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Container(
//                 height: 44,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(22),
//                   border: Border.all(color: Colors.pink.shade50, width: 1.5),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withValues(alpha: 0.08),
//                       blurRadius: 6,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: TextField(
//                   controller: _controller,
//                   style: const TextStyle(fontSize: 14),
//                   decoration: const InputDecoration(
//                     hintText: "Ask me questions...",
//                     hintStyle: TextStyle(color: Colors.black38),
//                     border: InputBorder.none,
//                   ),
//                   onSubmitted: (_) => _sendMessage(),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             AnimatedBuilder(
//               animation: _sendButtonController,
//               builder: (context, child) {
//                 final sine =
//                 math.sin(_sendButtonController.value * 2 * math.pi);
//                 final normalized = ((sine + 1) / 2).clamp(0.0, 1.0);
//                 final bg = Color.lerp(
//                     const Color(0xFFFF5BA5),
//                     const Color(0xFFFF85C2),
//                     1 - normalized)!;
//
//                 return Container(
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: bg,
//                     boxShadow: [
//                       BoxShadow(
//                         color:
//                         Colors.pinkAccent.withValues(alpha: 0.3 * normalized),
//                         blurRadius: 8 + (6 * normalized),
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.send_rounded,
//                         color: Colors.white, size: 20),
//                     onPressed: _sendMessage,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


//
// /// Panel opens from LEFT with slide + fade
// class _LeftSideSheetRoute extends PageRouteBuilder {
//   _LeftSideSheetRoute()
//       : super(
//     transitionDuration: const Duration(milliseconds: 400),
//     reverseTransitionDuration: const Duration(milliseconds: 300),
//     opaque: false,
//     pageBuilder: (context, animation, secondaryAnimation) {
//       return FadeTransition(
//         opacity:
//         CurvedAnimation(parent: animation, curve: Curves.easeInOut),
//         child: SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(-1, 0),
//             end: Offset.zero,
//           ).animate(
//             CurvedAnimation(
//                 parent: animation, curve: Curves.easeOutCubic),
//           ),
//           child: const _ChatHistoryPanel(),
//         ),
//       );
//     },
//   );
// }
//
// class _ChatHistoryPanel extends StatelessWidget {
//   const _ChatHistoryPanel({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: FractionallySizedBox(
//         widthFactor: 0.9,
//         child: Material(
//           color: Colors.white,
//           borderRadius: const BorderRadius.only(
//             topRight: Radius.circular(24),
//             bottomRight: Radius.circular(24),
//           ),
//           elevation: 8,
//           child: Column(
//             children: [
//               // HEADER
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 48, 16, 10),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: const BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Color(0xFFFFE6EF),
//                       ),
//                       child: const Icon(Icons.auto_awesome,
//                           color: Colors.pinkAccent),
//                     ),
//                     const SizedBox(width: 10),
//                     const Expanded(
//                       child: Text(
//                         "Ask our AI anything",
//                         style: TextStyle(
//                           fontSize: 17,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: const Icon(Icons.close_rounded,
//                           color: Colors.pinkAccent),
//                     ),
//                   ],
//                 ),
//               ),
//               const Divider(thickness: 0.5, height: 0),
//
//               // MAIN BODY
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 20),
//                   children: [
//                     // New Chat
//                     ListTile(
//                       contentPadding: EdgeInsets.zero,
//                       leading: const Icon(Icons.chat_bubble_outline_rounded,
//                           color: Colors.pinkAccent),
//                       title: const Text(
//                         "New Chat",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 15,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       trailing: const Icon(Icons.arrow_forward_ios_rounded,
//                           color: Colors.black45, size: 18),
//                       onTap: () => Navigator.pop(context),
//                     ),
//
//                     const SizedBox(height: 25),
//                     const Text(
//                       "Previous 7 Days",
//                       style: TextStyle(
//                         color: Colors.pinkAccent,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//
//                     // --- Flat previous chats (no layout) ---
//                     _flatChatRow("Plan my dream destination wedding"),
//                     const SizedBox(height: 8),
//                     _flatChatRow("Plan my dream destination wedding"),
//
//                     const SizedBox(height: 20),
//                     const Divider(thickness: 0.5, height: 0),
//
//                     const SizedBox(height: 12),
//
//                     // SUMMARY SECTION
//                     const Text(
//                       "✨ Summary",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.pinkAccent,
//                         fontSize: 15,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//
//                     _summaryRow("Budget", "50000"),
//                     const SizedBox(height: 10),
//                     _summaryRow("Guests", "500"),
//                     const SizedBox(height: 10),
//                     _summaryRow("City", "Pune"),
//
//                     const SizedBox(height: 18),
//                     const Text(
//                       "✨ Checklist",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.pinkAccent,
//                         fontSize: 15,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//
//                     Row(
//                       children: const [
//                         Icon(Icons.check_circle_outline,
//                             color: Colors.pinkAccent, size: 18),
//                         SizedBox(width: 8),
//                         Text("Venue - Delhi Club",
//                             style:
//                             TextStyle(color: Colors.black87, fontSize: 14)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//
//               const Divider(thickness: 0.5, height: 0),
//
//               // CLEAR BUTTON
//               Padding(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: GestureDetector(
//                   onTap: () {},
//                   child: Row(
//                     children: const [
//                       Icon(Icons.delete_outline_rounded,
//                           color: Colors.pinkAccent),
//                       SizedBox(width: 8),
//                       Text(
//                         "Clear conversations",
//                         style: TextStyle(
//                             color: Colors.black54,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // --- Flat Chat Row (no layout, no border, just text + menu) ---
//   static Widget _flatChatRow(String title) {
//     return Row(
//       children: [
//         const Icon(Icons.chat_bubble_outline_rounded,color: Colors.black54, size: 20),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Text(
//             title,
//             style: const TextStyle(
//               color: Colors.black87,
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//         PopupMenuButton<String>(
//           icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),
//           onSelected: (value) {},
//           shape:
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           itemBuilder: (context) => [
//             const PopupMenuItem<String>(
//               value: 'edit',
//               child: Row(
//                 children: [
//                   Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
//                   SizedBox(width: 8),
//                   Text("Edit"),
//                 ],
//               ),
//             ),
//             const PopupMenuItem<String>(
//               value: 'delete',
//               child: Row(
//                 children: [
//                   Icon(Icons.delete_outline_rounded,
//                       size: 18, color: Colors.redAccent),
//                   SizedBox(width: 8),
//                   Text("Delete",
//                       style: TextStyle(color: Colors.redAccent)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   static Widget _summaryRow(String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(label,
//             style: const TextStyle(color: Colors.black87, fontSize: 14)),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//           decoration: BoxDecoration(
//             color: const Color(0xFFFFE6EF),
//             borderRadius: BorderRadius.circular(30),
//           ),
//           child: Text(
//             value,
//             style: const TextStyle(
//                 color: Colors.pinkAccent,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
//




