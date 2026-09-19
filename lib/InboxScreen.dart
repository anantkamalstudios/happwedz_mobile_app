import 'package:flutter/material.dart';

import 'core/core.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_page_new.dart';

class Inboxscreen extends StatefulWidget {
  const Inboxscreen({super.key});

  @override
  _InboxscreenState createState() => _InboxscreenState();
}

class _InboxscreenState extends State<Inboxscreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isSearching = false;
  String _query = '';

  bool _loading = true;
  Object? _error;
  List<ConversationSummary> _conversations = const [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    _loadConversations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');

      final conversations = await ChatService.fetchConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ConversationSummary> get _visibleConversations {
    if (_query.isEmpty) return _conversations;
    final q = _query.toLowerCase();
    return _conversations
        .where((c) =>
            c.vendorName.toLowerCase().contains(q) ||
            c.lastMessagePreview.toLowerCase().contains(q))
        .toList();
  }

  void _openConversation(ConversationSummary c) {
    final currentUid = _currentUserId;
    if (currentUid == null) {
      AppSnackbar.info(context, 'Please sign in to continue.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          currentUid: currentUid,
          otherUid: c.vendorId,
          otherName: c.vendorName,
          vendorId: c.vendorId,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              // 🌸 Custom AppBar like Budget
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const AppBackButton(color: AppColors.textOnPrimary),
                    Expanded(
                      child: Text(
                        'Messages',
                        textAlign: TextAlign.center,
                        style: AppText.pageTitle.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44), // balances the back button
                  ],
                ),
              ),

              _buildSearchBar(),

              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadConversations,
                    child: _buildBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _conversations.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: LoadingShimmer(
            child: SkeletonBox(height: 64, radius: AppRadii.md),
          ),
        ),
      );
    }

    if (_error != null && _conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: ErrorState(error: _error, onRetry: _loadConversations),
          ),
        ],
      );
    }

    final visible = _visibleConversations;
    if (visible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 420, child: _buildEmptyState())],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _ConversationTile(
        conversation: visible[index],
        onTap: () => _openConversation(visible[index]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Color(0xFFE91E63), // Pink color from the design
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Chats',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            // _showOptionsMenu();
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppColors.shadowSm,
        ),
        child: TextField(
          controller: _searchController,
          style: AppText.body,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {
              _isSearching = value.isNotEmpty;
              _query = value.trim();
            });
          },
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search messages',
            hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _query = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: EmptyState(
          title: _isSearching ? 'No matching messages' : 'No messages yet',
          message: _isSearching
              ? 'Try a different search term.'
              : 'Message a vendor from their profile to start a conversation — it will show up here.',
          icon: Icons.chat_bubble_outline_rounded,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ConversationSummary conversation;
  final VoidCallback onTap;

  String _timeLabel(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${at.day}/${at.month}/${at.year}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadii.md,
      child: Row(
        children: [
          AppAvatar(url: conversation.vendorImage, name: conversation.vendorName, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.vendorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: unread ? AppText.bodyStrong : AppText.body,
                ),
                const SizedBox(height: 2),
                Text(
                  conversation.lastMessagePreview.isEmpty
                      ? 'No messages yet'
                      : conversation.lastMessagePreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySm.copyWith(
                    color: unread ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeLabel(conversation.lastMessageAt),
                style: AppText.caption.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 6),
              if (unread)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 20),
                  child: Text(
                    conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// The inbox previously had no real conversation list at all — it always
// rendered a hardcoded empty state (this is the "InboxScreen is a fully
// non-functional stub" bug fixed above). These accompanying UI pieces from
// that dead version were never wired into a real "start a new chat without
// an existing vendor" flow (this app only starts chats from a vendor's own
// page), so they're kept here, commented out, rather than deleted, per
// project convention — they can be revived if that flow is ever built.
//
// Widget _buildStartChattingButton() {
//   return Container(
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(25),
//       gradient: LinearGradient(
//         colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Color(0xFFE91E63).withValues(alpha: 0.3),
//           blurRadius: 15,
//           offset: Offset(0, 8),
//         ),
//       ],
//     ),
//     child: ElevatedButton(
//       onPressed: () {
//         _showStartChatOptions();
//       },
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.transparent,
//         shadowColor: Colors.transparent,
//         padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(25),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.add_comment, size: 20, color: Colors.white),
//           SizedBox(width: 8),
//           Text(
//             'Start Chatting',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
// Widget _buildFloatingActionButton() {
//   return Container(
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(30),
//       gradient: LinearGradient(
//         colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Color(0xFFE91E63).withValues(alpha: 0.4),
//           blurRadius: 15,
//           offset: Offset(0, 8),
//         ),
//       ],
//     ),
//     child: FloatingActionButton(
//       onPressed: () {
//         _showNewChatDialog();
//       },
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       child: Icon(
//         Icons.edit,
//         color: Colors.white,
//         size: 24,
//       ),
//     ),
//   );
// }
//
// void _showOptionsMenu() {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.transparent,
//     builder: (context) => Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 40,
//             height: 4,
//             margin: EdgeInsets.only(top: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           ListTile(
//             leading: Icon(Icons.group_add, color: Color(0xFFE91E63)),
//             title: Text('New Group'),
//             onTap: () => Navigator.pop(context),
//           ),
//           ListTile(
//             leading: Icon(Icons.settings, color: Color(0xFFE91E63)),
//             title: Text('Settings'),
//             onTap: () => Navigator.pop(context),
//           ),
//           ListTile(
//             leading: Icon(Icons.help_outline, color: Color(0xFFE91E63)),
//             title: Text('Help'),
//             onTap: () => Navigator.pop(context),
//           ),
//           SizedBox(height: 20),
//         ],
//       ),
//     ),
//   );
// }
//
// void _showStartChatOptions() {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.transparent,
//     builder: (context) => Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 40,
//             height: 4,
//             margin: EdgeInsets.only(top: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           SizedBox(height: 20),
//           Text(
//             'Start a new conversation',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//           SizedBox(height: 20),
//           ListTile(
//             leading: Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Color(0xFFE91E63).withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(Icons.person_add, color: Color(0xFFE91E63)),
//             ),
//             title: Text('Find People'),
//             subtitle: Text('Connect with new people'),
//             onTap: () => Navigator.pop(context),
//           ),
//           ListTile(
//             leading: Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Color(0xFFE91E63).withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(Icons.qr_code_scanner, color: Color(0xFFE91E63)),
//             ),
//             title: Text('Scan QR Code'),
//             subtitle: Text('Quick connect via QR'),
//             onTap: () => Navigator.pop(context),
//           ),
//           SizedBox(height: 30),
//         ],
//       ),
//     ),
//   );
// }
//
// void _showNewChatDialog() {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Text('New Chat'),
//       content: Text('Choose how you want to start a new conversation.'),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: Text('Cancel', style: TextStyle(color: Colors.grey)),
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.pop(context),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Color(0xFFE91E63),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: Text('Start Chat', style: TextStyle(color: Colors.white)),
//         ),
//       ],
//     ),
//   );
// }
