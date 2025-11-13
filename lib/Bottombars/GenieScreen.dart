import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:math' as math;



class GenieScreen extends StatefulWidget {
  const GenieScreen({super.key});

  @override
  State<GenieScreen> createState() => _GenieScreenState();
}

class _GenieScreenState extends State<GenieScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> messages = [
    {
      'isUser': false,
      'text':
      "Hi! I am Genie ✨\nHow can I help you plan your dream wedding today?",
    },
  ];

  late AnimationController _genieAnimation;
  late AnimationController _sendButtonController;

  @override
  void initState() {
    super.initState();
    _genieAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _genieAnimation.dispose();
    _sendButtonController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final userMsg = _controller.text.trim();
    setState(() {
      messages.add({'isUser': true, 'text': userMsg});
    });
    _controller.clear();

    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollToBottom();
    });

    // Simulated Genie reply
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add({
          'isUser': false,
          'text':
          "That sounds absolutely magical! 🎉 Let's start planning your dream destination wedding. Could you share which destination you're considering? 😊",
        });
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: FadeTransition(
          opacity:
          CurvedAnimation(parent: _genieAnimation, curve: Curves.easeIn),
          child: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Ask our AI anything",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.black87),
                      onPressed: () {
                        Navigator.of(context).push(_LeftSideSheetRoute());
                      },
                    ),


                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8FB), Color(0xFFFFEEF4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 1) {
                    // Show popular questions below the first Genie message
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Popular questions for you !",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        _buildSuggestionCard(
                          title: "Budget",
                          subtitle: "Plan my dream destination wedding",
                          icon: Icons.arrow_forward_ios_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildSuggestionCard(
                          title: "Venues",
                          subtitle: "Show me the best wedding venues",
                          icon: Icons.north_east_rounded,
                        ),
                      ],
                    );
                  }

                  if (index < messages.length) {
                    final msg = messages[index];
                    return msg['isUser']
                        ? _buildUserBubble(msg['text'])
                        : _buildGenieBubble(msg['text']);
                  }

                  return const SizedBox(height: 20);
                },
              ),
            ),
            _buildBottomInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenieBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pink.shade100, width: 1.5),
              color: Colors.white,
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.pinkAccent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.black87, height: 1.4),
                  ),
                ),
                const SizedBox(height: 6),
                _buildGenieActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenieActions() {
    final icons = [
      Icons.insert_drive_file_rounded,
      Icons.share_rounded,
      Icons.edit_rounded,
      Icons.favorite_border_rounded,
      Icons.location_on_rounded
    ];
    return Row(
      children: icons
          .map(
            (icon) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.pinkAccent, size: 16),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 10, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 15, color: Colors.black87)),
      ),
    );
  }

  Widget _buildSuggestionCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          messages.add({'isUser': true, 'text': subtitle});
        });
        _scrollToBottom();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.shade100.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                  ]),
            ),
            Icon(icon, color: Colors.pinkAccent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1AF06292),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE6F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.pinkAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.pink.shade50, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Ask me questions...",
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _sendButtonController,
              builder: (context, child) {
                final sine =
                math.sin(_sendButtonController.value * 2 * math.pi);
                final normalized = ((sine + 1) / 2).clamp(0.0, 1.0);
                final bg = Color.lerp(
                    const Color(0xFFFF5BA5),
                    const Color(0xFFFF85C2),
                    1 - normalized)!;

                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.pinkAccent.withOpacity(0.3 * normalized),
                        blurRadius: 8 + (6 * normalized),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}



/// Panel opens from LEFT with slide + fade
class _LeftSideSheetRoute extends PageRouteBuilder {
  _LeftSideSheetRoute()
      : super(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    opaque: false,
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity:
        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic),
          ),
          child: const _ChatHistoryPanel(),
        ),
      );
    },
  );
}

class _ChatHistoryPanel extends StatelessWidget {
  const _ChatHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          elevation: 8,
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFE6EF),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.pinkAccent),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Ask our AI anything",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.pinkAccent),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 0.5, height: 0),

              // MAIN BODY
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  children: [
                    // New Chat
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.pinkAccent),
                      title: const Text(
                        "New Chat",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.black45, size: 18),
                      onTap: () => Navigator.pop(context),
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      "Previous 7 Days",
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Flat previous chats (no layout) ---
                    _flatChatRow("Plan my dream destination wedding"),
                    const SizedBox(height: 8),
                    _flatChatRow("Plan my dream destination wedding"),

                    const SizedBox(height: 20),
                    const Divider(thickness: 0.5, height: 0),

                    const SizedBox(height: 12),

                    // SUMMARY SECTION
                    const Text(
                      "✨ Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _summaryRow("Budget", "50000"),
                    const SizedBox(height: 10),
                    _summaryRow("Guests", "500"),
                    const SizedBox(height: 10),
                    _summaryRow("City", "Pune"),

                    const SizedBox(height: 18),
                    const Text(
                      "✨ Checklist",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: const [
                        Icon(Icons.check_circle_outline,
                            color: Colors.pinkAccent, size: 18),
                        SizedBox(width: 8),
                        Text("Venue - Delhi Club",
                            style:
                            TextStyle(color: Colors.black87, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(thickness: 0.5, height: 0),

              // CLEAR BUTTON
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.pinkAccent),
                      SizedBox(width: 8),
                      Text(
                        "Clear conversations",
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Flat Chat Row (no layout, no border, just text + menu) ---
  static Widget _flatChatRow(String title) {
    return Row(
      children: [
        const Icon(Icons.chat_bubble_outline_rounded,color: Colors.black54, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.black54),
          onSelected: (value) {},
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
                  SizedBox(width: 8),
                  Text("Edit"),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text("Delete",
                      style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black87, fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE6EF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.pinkAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
      ],
    );
  }
}






