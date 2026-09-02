/// ShaadiAI — the wedding-planning assistant ported from `ShaadiAI.jsx`.
///
/// This is a different feature from the already-ported Genie chat
/// (`lib/ai_chat_screen/`, `lib/Bottombars/GenieScreen.dart`) despite both
/// being "AI chat" — different backend host, different endpoints, and this
/// one carries quiz/budget/vendor-comparison results inline.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/core.dart';
import '../../vendor/vendordetailsscreen.dart';
import '../data/shaadi_ai_api.dart';
import '../data/shaadi_ai_storage.dart';
import '../models/shaadi_ai_models.dart';
import 'widgets/conflict_resolver_form.dart';
import 'widgets/culture_blender_form.dart';
import 'widgets/personality_quiz_form.dart';
import 'widgets/shaadi_ai_message_cards.dart';
import 'widgets/shaadi_feature_results.dart';
import 'widgets/timeline_generator_form.dart';

/// Quoted verbatim from `ShaadiAI.jsx`'s `INITIAL_MSG`.
ShaadiChatMessage _initialMessage() => ShaadiChatMessage(
  role: 'assistant',
  content:
      "Namaste! 🙏 I'm Shaadi AI, your personal wedding planning assistant.\n\n"
      "Tell me what you're looking for — a venue, photographer, mehendi "
      "artist, decorator, DJ, or a full wedding plan?\n\n"
      "✨ Try these AI features:\n"
      "• /personality-quiz - Discover your wedding style\n"
      "• /culture-blender - Blend two cultures\n"
      "• /conflict-resolver - Resolve wedding decisions\n"
      "• /timeline-generator - Create your wedding timeline\n\n"
      "💡 Tip: You can also just say \"I want to take personality quiz\" or "
      '"help me blend cultures" and I\'ll understand!',
);

/// Slash commands, checked in this exact order — first prefix match wins.
const List<ShaadiFeatureType> _kSlashCommandOrder = [
  ShaadiFeatureType.personalityQuiz,
  ShaadiFeatureType.cultureBlender,
  ShaadiFeatureType.conflictResolver,
  ShaadiFeatureType.timelineGenerator,
];

/// Natural-language keyword lists, quoted verbatim from `ShaadiAI.jsx`.
/// Checked in this fixed order (personality → culture → conflict →
/// timeline); the first list with a substring match wins.
const Map<ShaadiFeatureType, List<String>> _kFeatureKeywords = {
  ShaadiFeatureType.personalityQuiz: [
    'personality quiz',
    'personality test',
    'wedding style',
    'wedding quiz',
    'discover my style',
    'find my style',
    'what style',
    'wedding personality',
    'take quiz',
    'take the quiz',
    'style quiz',
    'vibe quiz',
  ],
  ShaadiFeatureType.cultureBlender: [
    'culture blend',
    'blend culture',
    'culture blender',
    'mix culture',
    'fusion wedding',
    'multi cultural',
    'multicultural',
    'two culture',
    'combine culture',
    'merge culture',
    'cultural fusion',
    'blend my culture',
  ],
  ShaadiFeatureType.conflictResolver: [
    'conflict',
    'disagree',
    'disagreement',
    'resolve conflict',
    'conflict resolver',
    'husband wife conflict',
    'partner conflict',
    'couple conflict',
    'we disagree',
    "can't agree",
    'cannot agree',
    'help us decide',
    'mediate',
    'resolve decision',
    'solve conflict',
    'fix conflict',
  ],
  ShaadiFeatureType.timelineGenerator: [
    'timeline',
    'schedule',
    'wedding timeline',
    'day timeline',
    'event timeline',
    'generate timeline',
    'create timeline',
    'make timeline',
    'plan timeline',
    'wedding schedule',
    'event schedule',
    'day schedule',
    'timing',
    'time management',
    'wedding day plan',
  ],
};

const List<ShaadiFeatureType> _kKeywordCheckOrder = [
  ShaadiFeatureType.personalityQuiz,
  ShaadiFeatureType.cultureBlender,
  ShaadiFeatureType.conflictResolver,
  ShaadiFeatureType.timelineGenerator,
];

class ShaadiAiScreen extends StatefulWidget {
  const ShaadiAiScreen({super.key});

  @override
  State<ShaadiAiScreen> createState() => _ShaadiAiScreenState();
}

class _ShaadiAiScreenState extends State<ShaadiAiScreen> {
  final ShaadiAiApi _api = ShaadiAiApi();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ShaadiChatMessage> _messages = [_initialMessage()];
  String? _activeChatId;
  List<ShaadiChatSession> _chatList = [];
  bool _loading = false;
  String? _recommendationsLens;

  bool get _isInitialState => _messages.length == 1 && _activeChatId == null;

  @override
  void initState() {
    super.initState();
    _loadChatList();
    _loadRecommendationsLens();
  }

  @override
  void dispose() {
    _api.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChatList() async {
    final chats = await ShaadiAiStorage.loadChats();
    if (!mounted) return;
    setState(() => _chatList = chats);
  }

  Future<void> _loadRecommendationsLens() async {
    final lens = await ShaadiAiStorage.loadRecommendationsLens();
    if (!mounted) return;
    setState(() => _recommendationsLens = lens);
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Sending
  // ---------------------------------------------------------------------

  Future<void> _handleSend([String? customMessage]) async {
    final userMsg = customMessage ?? _inputCtrl.text.trim();
    if (userMsg.isEmpty) return;

    final lower = userMsg.toLowerCase();

    ShaadiFeatureType? slashCommand;
    for (final feature in _kSlashCommandOrder) {
      if (lower.startsWith('/${feature.slug}')) {
        slashCommand = feature;
        break;
      }
    }

    if (slashCommand != null) {
      setState(() {
        _messages = [
          ..._messages,
          ShaadiChatMessage(role: 'user', content: userMsg),
          ShaadiChatMessage(
            role: 'assistant',
            content: 'Opening ${slashCommand!.label.toLowerCase()}...',
            featureType: slashCommand,
          ),
        ];
      });
      if (customMessage == null) _inputCtrl.clear();
      await _saveCurrentChat();
      _scrollToBottom();
      return;
    }

    ShaadiFeatureType? detected;
    for (final feature in _kKeywordCheckOrder) {
      final keywords = _kFeatureKeywords[feature]!;
      if (keywords.any(lower.contains)) {
        detected = feature;
        break;
      }
    }

    if (detected != null) {
      setState(() {
        _messages = [
          ..._messages,
          ShaadiChatMessage(role: 'user', content: userMsg),
          ShaadiChatMessage(
            role: 'assistant',
            content:
                'I detected you want to use the ${detected!.label}! '
                'Opening it for you...',
            featureType: detected,
          ),
        ];
      });
      if (customMessage == null) _inputCtrl.clear();
      await _saveCurrentChat();
      _scrollToBottom();
      return;
    }

    final updated = [..._messages, ShaadiChatMessage(role: 'user', content: userMsg)];
    setState(() {
      _messages = updated;
      _loading = true;
    });
    if (customMessage == null) _inputCtrl.clear();
    _scrollToBottom();

    try {
      // Every message except the intro and any feature-open placeholder —
      // matches `ShaadiAI.jsx`'s `historyForBackend` exactly.
      final history = updated
          .skip(1)
          .where((m) => m.featureType == null)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final reply = await _api.sendChat(
        message: userMsg,
        conversationHistory: history,
      );

      if (!mounted) return;
      setState(() {
        _messages = [...updated, reply];
        _loading = false;
      });
      await _saveCurrentChat();
    } on ShaadiAiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = [
          ...updated,
          ShaadiChatMessage(role: 'assistant', content: e.message),
        ];
        _loading = false;
      });
      // Matches the source: a failed /ai/chat turn is shown but not saved.
    }
    _scrollToBottom();
  }

  /// Called by an inline feature form with either the typed result or a
  /// `String` error message.
  Future<void> _handleFeatureComplete(
    ShaadiFeatureType type,
    Object result,
  ) async {
    if (result is String) {
      setState(() {
        _messages = [
          ..._messages,
          ShaadiChatMessage(role: 'assistant', content: result),
        ];
      });
      _scrollToBottom();
      return;
    }

    if (type == ShaadiFeatureType.personalityQuiz &&
        result is PersonalityQuizResult) {
      await ShaadiAiStorage.savePersonalityProfile(result);
      if (mounted) setState(() => _recommendationsLens = result.recommendationsLens);
    }

    setState(() {
      _messages = [
        ..._messages,
        ShaadiChatMessage(
          role: 'assistant',
          content:
              'Here are your ${type.label.toLowerCase()} results! Feel free '
              'to ask me any questions about them.',
          featureType: type,
          featureResult: result,
        ),
      ];
    });
    await _saveCurrentChat();
    _scrollToBottom();
  }

  Future<void> _saveCurrentChat() async {
    final id = _activeChatId ?? ShaadiAiStorage.newSessionId();
    final session = ShaadiChatSession(
      id: id,
      title: ShaadiChatSession.titleFor(_messages),
      messages: _messages,
      updatedAt: DateTime.now(),
    );
    await ShaadiAiStorage.saveChat(session);
    if (!mounted) return;
    setState(() => _activeChatId = id);
    await _loadChatList();
  }

  // ---------------------------------------------------------------------
  // Sidebar actions
  // ---------------------------------------------------------------------

  void _handleNewChat() {
    setState(() {
      _messages = [_initialMessage()];
      _activeChatId = null;
      _inputCtrl.clear();
    });
    Navigator.of(context).maybePop();
  }

  void _handleLoadChat(ShaadiChatSession session) {
    setState(() {
      _messages = session.messages.isEmpty ? [_initialMessage()] : session.messages;
      _activeChatId = session.id;
    });
    Navigator.of(context).maybePop();
  }

  Future<void> _handleDeleteChat(String id) async {
    await ShaadiAiStorage.deleteChat(id);
    if (_activeChatId == id) {
      setState(() {
        _messages = [_initialMessage()];
        _activeChatId = null;
      });
    }
    await _loadChatList();
  }

  // ---------------------------------------------------------------------
  // Result-card callbacks
  // ---------------------------------------------------------------------

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

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      drawer: _Sidebar(
        chats: _chatList,
        activeChatId: _activeChatId,
        onNewChat: _handleNewChat,
        onLoadChat: _handleLoadChat,
        onDeleteChat: _handleDeleteChat,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: Text('Shaadi AI', style: AppText.pageTitle),
      ),
      body: SafeArea(
        child: _isInitialState ? _buildHome() : _buildChat(),
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          const Icon(Icons.auto_awesome, size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Shaadi AI',
            style: AppText.display,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _InputBar(
            controller: _inputCtrl,
            loading: _loading,
            onSend: () => _handleSend(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Icon(Icons.auto_fix_high, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Try Shaadi AI', style: AppText.label.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SuggestionGrid(onTap: _handleSend),
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            // Index 0 (the intro message) is never shown, matching the
            // source's `if (index === 0) return null;`.
            itemCount: (_messages.length - 1) + (_loading ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= _messages.length - 1) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: _TypingIndicator(),
                );
              }
              final message = _messages[i + 1];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: _MessageBlock(
                  message: message,
                  onVendorTap: _onVendorTap,
                  onProductTap: _onProductTap,
                  onFeatureComplete: (result) =>
                      _handleFeatureComplete(message.featureType!, result),
                  recommendationsLens: _recommendationsLens,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: _InputBar(
            controller: _inputCtrl,
            loading: _loading,
            onSend: () => _handleSend(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Message block — text, then whichever open form / result / card block
// applies, in the fixed order from `ShaadiAI.jsx`.
// ---------------------------------------------------------------------------

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.message,
    required this.onVendorTap,
    required this.onProductTap,
    required this.onFeatureComplete,
    required this.recommendationsLens,
  });

  final ShaadiChatMessage message;
  final void Function(String vendorId) onVendorTap;
  final void Function(String url) onProductTap;
  final void Function(Object result) onFeatureComplete;
  final String? recommendationsLens;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (isUser)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadii.rMd,
                  ),
                  child: Text(
                    message.content,
                    style: AppText.body.copyWith(color: Colors.white),
                  ),
                )
              else if (message.content.isNotEmpty)
                Text(message.content, style: AppText.body),

              if (message.featureType != null && message.featureResult == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _FeatureForm(
                    type: message.featureType!,
                    recommendationsLens: recommendationsLens,
                    onComplete: onFeatureComplete,
                  ),
                ),

              if (message.featureResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _FeatureResult(
                    type: message.featureType!,
                    result: message.featureResult,
                  ),
                ),

              if (message.hasResults)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: ShaadiMessageResults(
                    message: message,
                    onVendorTap: onVendorTap,
                    onProductTap: onProductTap,
                  ),
                ),
            ],
          ),
        ),
        if (isUser) const SizedBox(width: AppSpacing.sm + 32),
      ],
    );
  }
}

class _FeatureForm extends StatelessWidget {
  const _FeatureForm({
    required this.type,
    required this.recommendationsLens,
    required this.onComplete,
  });

  final ShaadiFeatureType type;
  final String? recommendationsLens;
  final void Function(Object result) onComplete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: switch (type) {
        ShaadiFeatureType.personalityQuiz => PersonalityQuizForm(
          recommendationsLens: recommendationsLens,
          onComplete: onComplete,
        ),
        ShaadiFeatureType.cultureBlender => CultureBlenderForm(
          recommendationsLens: recommendationsLens,
          onComplete: onComplete,
        ),
        ShaadiFeatureType.conflictResolver => ConflictResolverForm(
          recommendationsLens: recommendationsLens,
          onComplete: onComplete,
        ),
        ShaadiFeatureType.timelineGenerator => TimelineGeneratorForm(
          recommendationsLens: recommendationsLens,
          onComplete: onComplete,
        ),
      },
    );
  }
}

class _FeatureResult extends StatelessWidget {
  const _FeatureResult({required this.type, required this.result});

  final ShaadiFeatureType type;
  final dynamic result;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      ShaadiFeatureType.personalityQuiz =>
        PersonalityQuizResultCard(result: result as PersonalityQuizResult),
      ShaadiFeatureType.cultureBlender =>
        CultureBlenderResultCard(result: result as CultureBlenderResult),
      ShaadiFeatureType.conflictResolver =>
        ConflictResolverResultCard(result: result as ConflictResolverResult),
      ShaadiFeatureType.timelineGenerator =>
        TimelineResultCard(items: result as List<TimelineItem>),
    };
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
        ),
        SizedBox(width: AppSpacing.sm),
        _TypingDots(),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pinkSurface,
        borderRadius: AppRadii.rMd,
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final dots = (_c.value * 3).floor() + 1;
          return Text('.' * dots, style: AppText.sectionTitle);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home-state suggestion grid — quoted verbatim from `ShaadiAI.jsx`.
// ---------------------------------------------------------------------------

class _SuggestionGrid extends StatelessWidget {
  const _SuggestionGrid({required this.onTap});

  final void Function(String message) onTap;

  static const _tiles = [
    (
      emoji: '💍 Plan Wedding',
      caption: 'Plan a full wedding in Mumbai for 15 lakhs',
      message: 'Plan a full wedding in Mumbai for 15 lakhs',
    ),
    (
      emoji: '🏰 Bohemian Venue',
      caption: 'Find me a bohemian venue in Delhi',
      message: 'Find me a bohemian venue in Delhi',
    ),
    (
      emoji: '💕 Personality Quiz',
      caption: 'Discover your unique wedding style',
      message: '/personality-quiz',
    ),
    (
      emoji: '✨ Culture Blender',
      caption: 'Blend two cultures beautifully',
      message: '/culture-blender',
    ),
    (
      emoji: '⚖️ Conflict Resolver',
      caption: 'Resolve wedding decisions together',
      message: '/conflict-resolver',
    ),
    (
      emoji: '📅 Timeline Generator',
      caption: 'Create your wedding timeline',
      message: '/timeline-generator',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.4,
      children: [
        for (final tile in _tiles)
          Pressable(
            onTap: () => onTap(tile.message),
            borderRadius: AppRadii.rMd,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tile.emoji, style: AppText.labelSm),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    tile.caption,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Ask anything about your wedding...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSend = value.text.trim().isNotEmpty && !loading;
              return IconButton(
                onPressed: canSend ? onSend : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: canSend ? AppColors.primary : AppColors.textTertiary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar (Drawer) — chat list, matches `renderSidebar()`.
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.chats,
    required this.activeChatId,
    required this.onNewChat,
    required this.onLoadChat,
    required this.onDeleteChat,
  });

  final List<ShaadiChatSession> chats;
  final String? activeChatId;
  final VoidCallback onNewChat;
  final void Function(ShaadiChatSession session) onLoadChat;
  final void Function(String id) onDeleteChat;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('Shaadi AI', style: AppText.sectionTitle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PremiumButton(
                label: 'New Chat',
                icon: Icons.add,
                onPressed: onNewChat,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Recent',
                style: AppText.labelSm.copyWith(color: AppColors.textTertiary),
              ),
            ),
            Expanded(
              child: chats.isEmpty
                  ? Center(
                      child: Text(
                        'No saved chats yet',
                        style: AppText.caption.copyWith(color: AppColors.textTertiary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: chats.length,
                      itemBuilder: (context, i) {
                        final chat = chats[i];
                        final isActive = chat.id == activeChatId;
                        return ListTile(
                          selected: isActive,
                          selectedTileColor: AppColors.pinkSurface,
                          leading: const Icon(Icons.chat_bubble_outline, size: 18),
                          title: Text(
                            chat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySm,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => onDeleteChat(chat.id),
                          ),
                          onTap: () => onLoadChat(chat),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
