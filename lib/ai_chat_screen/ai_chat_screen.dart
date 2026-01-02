import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class VendorAi {
  final String location;
  final String name;
  final int rating;
  final String type;
  final List<String> whyConsider;

  VendorAi({
    required this.location,
    required this.name,
    required this.rating,
    required this.type,
    required this.whyConsider,
  });

  factory VendorAi.fromJson(Map<String, dynamic> j) => VendorAi(
    location: j['location'] ?? '',
    name: j['name'] ?? '',
    rating: (j['rating'] is int)
        ? j['rating']
        : int.tryParse('${j['rating']}') ?? 0,
    type: j['type'] ?? '',
    whyConsider:
        (j['why_consider'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
  );
}

class AssistantResponse {
  final String message;
  final List<VendorAi> results;
  final bool showWishlist;
  final String summary;

  AssistantResponse({
    required this.message,
    required this.results,
    required this.showWishlist,
    required this.summary,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> j) {
    final results = <VendorAi>[];
    if (j['results'] is List) {
      for (var r in j['results']) {
        if (r is Map<String, dynamic>) results.add(VendorAi.fromJson(r));
      }
    }
    return AssistantResponse(
      message: j['message'] ?? '',
      results: results,
      showWishlist: j['show_wishlist'] ?? false,
      summary: j['summary'] ?? '',
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://shaadiai.happywedz.com';

  Future<Map<String, dynamic>> postUserChat({
    required int userId,
    String? sessionId,
    required String userQuery,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user_chat');
    final body = {
      'user_id': userId,
      'user_query': userQuery,
      if (sessionId != null) 'session_id': sessionId,
    };
    final resp = await http.post(
      uri,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to post chat: ${resp.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getChatHistory(String sessionId) async {
    final uri = Uri.parse('$baseUrl/api/chat_history?session_id=$sessionId');
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch history');
    }
  }

  Future<Map<String, dynamic>> getSessions(int userId) async {
    final uri = Uri.parse('$baseUrl/api/sessions/$userId');
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch sessions');
    }
  }
}

class MessageItem {
  final String role; // 'user' or 'assistant'
  final dynamic content; // String or AssistantResponse
  final DateTime timestamp;

  MessageItem({required this.role, required this.content, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class ChatProvider extends ChangeNotifier {
  final ApiService api = ApiService();

  final List<MessageItem> _messages = [];
  List<MessageItem> get messages => List.unmodifiable(_messages);

  String? sessionId;
  bool isLoading = false;
  String? error;

  int? userId;

  void setUserId(int id) {
    userId = id;
    notifyListeners();
  }

  Future<void> startNewChat({String? existingSessionId}) async {
    _messages.clear();

    // ⬇️ LOAD LOCAL CHAT STORAGE
    final localMsgs = await LocalChatStorage.loadMessages();
    _messages.addAll(localMsgs);

    sessionId = existingSessionId;
    error = null;
    notifyListeners();

    if (sessionId != null) {
      await fetchHistory(sessionId!);
    }
  }

  Future<void> fetchHistory(String sessId) async {
    try {
      isLoading = true;
      notifyListeners();
      final data = await api.getChatHistory(sessId);
      final arr = data['data'] as List<dynamic>? ?? [];
      _messages.clear();
      for (var item in arr) {
        final role = item['role'] ?? 'assistant';
        final contentRaw = item['content'];
        dynamic content;
        if (contentRaw is String) {
          content = contentRaw;
        } else if (contentRaw is Map<String, dynamic>) {
          content = AssistantResponse.fromJson(contentRaw);
        } else {
          content = contentRaw.toString();
        }
        _messages.add(MessageItem(role: role, content: content));
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (userId == null || userId == 0) {
      throw Exception("User is not logged in.");
    }

    // USER MESSAGE
    final userMessage = MessageItem(role: 'user', content: text);
    _messages.add(userMessage);

    // SAVE to SharedPreferences
    await LocalChatStorage.saveMessages(_messages);

    isLoading = true;
    notifyListeners();

    try {
      final resp = await api.postUserChat(
        userId: userId!,
        sessionId: sessionId,
        userQuery: text,
      );

      final data = resp['data'] as Map<String, dynamic>?;
      if (data != null) {
        sessionId = data['session_id'] ?? sessionId;

        final response = data['response'];
        dynamic assistantContent;

        if (response == null) {
          assistantContent = 'No response';
        } else if (response is Map<String, dynamic>) {
          assistantContent = AssistantResponse.fromJson(response);
        } else {
          assistantContent = response.toString();
        }

        // ASSISTANT MESSAGE
        _messages.add(
          MessageItem(role: 'assistant', content: assistantContent),
        );

        // SAVE again to SharedPreferences
        await LocalChatStorage.saveMessages(_messages);
      }
    } catch (e) {
      _messages.add(MessageItem(role: 'assistant', content: 'Error: $e'));

      // SAVE error message also
      await LocalChatStorage.saveMessages(_messages);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class MessageBubble extends StatelessWidget {
  final MessageItem message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final bg = isUser ? Colors.pink.shade50 : Colors.grey.shade100;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    Widget contentWidget;
    if (message.content is String) {
      contentWidget = Text(
        message.content as String,
        style: const TextStyle(fontSize: 15),
      );
    } else if (message.content is AssistantResponse) {
      final ar = message.content as AssistantResponse;
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ar.summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                ar.summary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          if (ar.message.isNotEmpty) Text(ar.message),
          if (ar.results.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Brief list preview
            Text(
              'Found ${ar.results.length} vendor(s). Tap to view cards.',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      );
    } else {
      contentWidget = Text(message.content.toString());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isUser) _Avatar(assistant: true),
              if (!isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: bg, borderRadius: radius),
                  child: contentWidget,
                ),
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser) _Avatar(assistant: false),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat.Hm().format(message.timestamp),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool assistant;
  const _Avatar({required this.assistant});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: assistant ? Colors.pink : Colors.grey.shade300,
      child: assistant
          ? const Icon(Icons.smart_toy_outlined, size: 18, color: Colors.white)
          : const Icon(Icons.person, size: 18, color: Colors.black54),
    );
  }
}

class VendorCard extends StatelessWidget {
  final VendorAi vendor;
  final VoidCallback? onTap;
  final VoidCallback? onWishlist;

  const VendorCard({
    super.key,
    required this.vendor,
    this.onTap,
    this.onWishlist,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    vendor.name.isNotEmpty ? vendor.name[0] : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vendor.type} • ${vendor.location}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: vendor.whyConsider.take(3).map((w) {
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(w, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.pink.shade50,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  Text(
                    '${vendor.rating}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: onWishlist,
                    icon: const Icon(Icons.favorite_border, color: Colors.pink),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    provider.startNewChat(); // no session initially
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    Provider.of<ChatProvider>(context, listen: false).sendUserMessage(text);
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 300), () => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _openNewChatMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.chat, color: Colors.pink),
                title: Text("Start New Chat"),
                onTap: () async {
                  Navigator.pop(context);

                  final prov = Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  );

                  // CLEAR LOCAL SAVED CHAT
                  await LocalChatStorage.clear();

                  // CLEAR PROVIDER CHAT
                  await prov.startNewChat(existingSessionId: null);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Started a new chat")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, prov, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        bool _shouldShowVendorCards(ChatProvider prov) {
          if (prov.messages.isEmpty) return false;
          final last = prov.messages.last;
          if (last.content is! AssistantResponse) return false;
          return (last.content as AssistantResponse).results.isNotEmpty;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'ShaadiAi Assistant',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    prov.startNewChat(existingSessionId: prov.sessionId),
                tooltip: 'Reload history',
              ),
              IconButton(
                icon: const Icon(Icons.list_alt),
                onPressed: _openSessionsModal,
                tooltip: 'Sessions',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: prov.isLoading && prov.messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        // itemCount: prov.messages.length + 1,
                        //   itemCount: prov.messages.length + (prov.isLoading ? 1 : 0),
                        //
                        //   itemBuilder: (context, idx) {
                        // if (idx == prov.messages.length) {
                        // // If last assistant message contains Vendor results, show them
                        // if (prov.messages.isNotEmpty) {
                        // final last = prov.messages.last;
                        // if (last.content is AssistantResponse) {
                        // final ar = last.content as AssistantResponse;
                        // if (ar.results.isNotEmpty) {
                        // return Column(
                        // children: ar.results.map((v) {
                        // return VendorCard(
                        // vendor: v,
                        // onTap: () => _showVendorDetails(v),
                        // // onWishlist: () => _addToWishlist(v),
                        // );
                        // }).toList(),
                        // );
                        // }
                        // }
                        // }
                        // return const SizedBox.shrink();
                        // }
                        //
                        // final msg = prov.messages[idx];
                        // return MessageBubble(message: msg);
                        // },
                        itemCount:
                            prov.messages.length +
                            (prov.isLoading
                                ? 1
                                : 0) + // typing indicator extra row
                            (_shouldShowVendorCards(prov)
                                ? 1
                                : 0), // vendor cards extra row

                        itemBuilder: (context, idx) {
                          final vendorCardsIndex = prov.messages.length;
                          final typingIndex =
                              prov.messages.length +
                              (_shouldShowVendorCards(prov) ? 1 : 0);

                          // 1️⃣ Vendor Cards Section
                          if (_shouldShowVendorCards(prov) &&
                              idx == vendorCardsIndex) {
                            final last = prov.messages.last;
                            final ar = last.content as AssistantResponse;

                            return Column(
                              children: ar.results.map((v) {
                                return VendorCard(
                                  vendor: v,
                                  onTap: () => _showVendorDetails(v),
                                );
                              }).toList(),
                            );
                          }

                          // 2️⃣ Typing Indicator
                          if (prov.isLoading && idx == typingIndex) {
                            return const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: AITypingIndicator(),
                            );
                          }

                          // 3️⃣ Normal messages
                          return MessageBubble(message: prov.messages[idx]);
                        },
                      ),
              ),

              // Input bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _openNewChatMenu,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.pink,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Ask about vendors, venues, budgets...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.pink,
                        child: IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSessionsModal() {
    final prov = Provider.of<ChatProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return FutureBuilder(
          future: prov.api.getSessions(prov.userId ?? 0),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return SizedBox(
                height: 200,
                child: Center(child: Text('Error: ${snap.error}')),
              );
            }
            final m = snap.data as Map<String, dynamic>;
            final list = m['data'] as List<dynamic>? ?? [];
            return ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, i) {
                final it = list[i] as Map<String, dynamic>;
                final title =
                    it['title'] ?? 'Session ${it['session_id'] ?? it['id']}';
                final sid = it['session_id'] ?? it['session_id'];
                final updated = it['updated_at'] ?? '';
                return ListTile(
                  title: Text(title),
                  subtitle: Text(updated),
                  onTap: () {
                    Navigator.of(context).pop();
                    // load that session
                    prov.startNewChat(existingSessionId: sid);
                  },
                );
              },
              separatorBuilder: (_, __) => const Divider(),
              itemCount: list.length,
            );
          },
        );
      },
    );
  }

  void _showVendorDetails(VendorAi v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      v.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.pink),
                        const SizedBox(width: 6),
                        Text(v.location),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text('${v.rating}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Why consider',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: v.whyConsider
                          .map((s) => Chip(label: Text(s)))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // _addToWishlist(v);
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Add to Wishlist'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // void _addToWishlist(VendorAi v) {
  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${v.name} added to wishlist (mock)')));
  // // TODO: call real wishlist API
  // }
}

class LocalChatStorage {
  static const String keyChatMessages = "chat_messages";

  static Future<void> saveMessages(List<MessageItem> messages) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> encoded = messages.map((m) {
      return {
        "role": m.role,
        "timestamp": m.timestamp.toIso8601String(),
        "content": _encodeContent(m.content),
      };
    }).toList();

    prefs.setString(keyChatMessages, jsonEncode(encoded));
  }

  static dynamic _encodeContent(dynamic content) {
    if (content is String) {
      return {"type": "string", "data": content};
    } else if (content is AssistantResponse) {
      return {
        "type": "assistant",
        "data": {
          "message": content.message,
          "summary": content.summary,
          "show_wishlist": content.showWishlist,
          "results": content.results
              .map(
                (v) => {
                  "name": v.name,
                  "location": v.location,
                  "type": v.type,
                  "rating": v.rating,
                  "why_consider": v.whyConsider,
                },
              )
              .toList(),
        },
      };
    }
    return {"type": "unknown", "data": content.toString()};
  }

  static Future<List<MessageItem>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyChatMessages);

    if (raw == null) return [];

    List decoded = jsonDecode(raw);

    return decoded.map((m) {
      final role = m["role"];
      final ts = DateTime.parse(m["timestamp"]);
      final content = _decodeContent(m["content"]);

      return MessageItem(role: role, content: content, timestamp: ts);
    }).toList();
  }

  static dynamic _decodeContent(Map<String, dynamic> m) {
    final type = m["type"];
    final data = m["data"];

    if (type == "string") return data;

    if (type == "assistant") {
      return AssistantResponse(
        message: data["message"],
        summary: data["summary"],
        showWishlist: data["show_wishlist"],
        results: (data["results"] as List).map((v) {
          return VendorAi(
            name: v["name"],
            location: v["location"],
            type: v["type"],
            rating: v["rating"],
            whyConsider: List<String>.from(v["why_consider"] ?? []),
          );
        }).toList(),
      );
    }

    return data.toString();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(keyChatMessages);
  }
}

class AITypingIndicator extends StatefulWidget {
  const AITypingIndicator({super.key});

  @override
  State<AITypingIndicator> createState() => _AITypingIndicatorState();
}

class _AITypingIndicatorState extends State<AITypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.pink,
          child: Icon(Icons.smart_toy_outlined, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            int dot = (_controller.value * 3).floor() + 1;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("." * dot, style: const TextStyle(fontSize: 22)),
            );
          },
        ),
      ],
    );
  }
}
