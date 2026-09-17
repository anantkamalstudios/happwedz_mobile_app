   import 'dart:convert';
import 'package:flutter/material.dart';

import '../core/core.dart';
import '../shaadi_ai/data/shaadi_ai_api.dart';
import '../shaadi_ai/models/shaadi_ai_models.dart';
import '../shaadi_ai/ui/widgets/shaadi_ai_message_cards.dart';
import '../vendor/vendordetailsscreen.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// AUDIT FIX: this screen ("ShaadiAi Assistant") and `lib/shaadi_ai/` are the
/// same product feature reached from two places in the app, not two
/// different backends as an earlier pass here assumed. The original
/// `/api/user_chat`, `/api/chat_history` and `/api/sessions/:id` endpoints
/// (ported from the old `Genie.jsx`, which called the now-dead
/// `shaadiai.happywedz.com` host) were never migrated anywhere — confirmed
/// live: every path variant under `api.happywedz.com/ai/...` returns
/// `{"success":false,"message":"Route not found"}`. The only working chat
/// endpoint on the consolidated backend is `POST /ai/chat`
/// (`ApiConfig.apiBase`), already used successfully by
/// `lib/shaadi_ai/data/shaadi_ai_api.dart`'s `sendChat`. This screen now
/// calls that same endpoint through the same `ShaadiAiApi`/`ShaadiChatMessage`
/// types instead of a parallel, broken implementation. There is no backend
/// session/history endpoint to restore, so — like ShaadiAI — history is
/// local-only (`LocalChatStorage`, below).
const String kNoAssistantResponse = 'No response found';

class ChatProvider extends ChangeNotifier {
  final ShaadiAiApi _api = ShaadiAiApi();

  List<ShaadiChatMessage> _messages = [];
  List<ShaadiChatMessage> get messages => List.unmodifiable(_messages);

  bool isLoading = false;
  String? error;

  Future<void> startNewChat() async {
    _messages = await LocalChatStorage.loadMessages();
    error = null;
    notifyListeners();
  }

  Future<void> clearChat() async {
    _messages = [];
    await LocalChatStorage.clear();
    notifyListeners();
  }

  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final updated = [
      ..._messages,
      ShaadiChatMessage(role: 'user', content: trimmed),
    ];
    _messages = updated;
    isLoading = true;
    error = null;
    notifyListeners();
    await LocalChatStorage.saveMessages(_messages);

    try {
      final history = updated
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final reply = await _api.sendChat(
        message: trimmed,
        conversationHistory: history,
      );
      _messages = [...updated, reply];
    } on ShaadiAiException catch (e) {
      debugPrint('ShaadiAi chat failed: ${e.message}');
      _messages = [
        ...updated,
        ShaadiChatMessage(role: 'assistant', content: e.message),
      ];
    } catch (e) {
      debugPrint('ShaadiAi chat failed: $e');
      _messages = [
        ...updated,
        ShaadiChatMessage(role: 'assistant', content: kNoAssistantResponse),
      ];
    } finally {
      isLoading = false;
      notifyListeners();
      await LocalChatStorage.saveMessages(_messages);
    }
  }
}

class MessageBubble extends StatelessWidget {
  final ShaadiChatMessage message;
  final void Function(String vendorId) onVendorTap;
  final void Function(String url) onProductTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onVendorTap,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.content.trim().isNotEmpty)
                        Text(
                          message.content,
                          style: const TextStyle(fontSize: 15),
                        ),
                      if (message.hasResults)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ShaadiMessageResults(
                            message: message,
                            onVendorTap: onVendorTap,
                            onProductTap: onProductTap,
                          ),
                        ),
                    ],
                  ),
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
    Provider.of<ChatProvider>(context, listen: false).startNewChat();
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

  void _onNewChat() async {
    final prov = Provider.of<ChatProvider>(context, listen: false);
    await prov.clearChat();
    if (!mounted) return;
    AppSnackbar.info(context, "Started a new chat");
  }

  void _onVendorTap(String vendorId) {
    if (vendorId.isEmpty) return;
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: VendorDetailsScreen(
          service: {
            'vendor': {'id': vendorId},
          },
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
  }

  Future<void> _onProductTap(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing sensible to recover to — a broken product link isn't
      // something the app can fix.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, prov, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'ShaadiAi Assistant',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _onNewChat,
                tooltip: 'Start new chat',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: prov.isLoading && prov.messages.isEmpty
                    ? const AppLoader()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        itemCount:
                            prov.messages.length + (prov.isLoading ? 1 : 0),
                        itemBuilder: (context, idx) {
                          if (idx == prov.messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: AITypingIndicator(),
                            );
                          }
                          return MessageBubble(
                            message: prov.messages[idx],
                            onVendorTap: _onVendorTap,
                            onProductTap: _onProductTap,
                          );
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
}

/// There is no backend session/history endpoint for this chat (same
/// situation as `lib/shaadi_ai/data/shaadi_ai_storage.dart` documents for
/// ShaadiAI) — this is the only place the conversation is persisted.
class LocalChatStorage {
  static const String keyChatMessages = "chat_messages";

  static Future<void> saveMessages(List<ShaadiChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = messages.map((m) => m.toJson()).toList();
    await prefs.setString(keyChatMessages, jsonEncode(encoded));
  }

  static Future<List<ShaadiChatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyChatMessages);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map(_decodeEntry).map(ShaadiChatMessage.fromJson).toList();
    } catch (e) {
      debugPrint('ShaadiAi local history unreadable, discarding: $e');
      return [];
    }
  }

  /// Cache written before this screen switched to [ShaadiChatMessage] wrapped
  /// every message's text as `{"type": ..., "data": ...}`. Left as-is, that
  /// shows up as a literal `{type: string, data: hi}` bubble — confirmed on a
  /// real device with pre-fix chat history still cached. Unwrap it to plain
  /// text before handing the entry to `ShaadiChatMessage.fromJson`; anything
  /// already in the current shape passes through untouched.
  static dynamic _decodeEntry(dynamic entry) {
    if (entry is! Map) return entry;
    final content = entry['content'];
    if (content is! Map || !content.containsKey('type')) return entry;

    final data = content['data'];
    final text = switch (content['type']) {
      'string' => data?.toString() ?? '',
      'assistant' when data is Map =>
        (data['summary'] as String?)?.trim().isNotEmpty == true
            ? data['summary']
            : (data['message'] as String?) ?? '',
      _ => data?.toString() ?? '',
    };
    return {...entry, 'content': text};
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyChatMessages);
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
