import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class FriendListView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onAddFriend;

  const FriendListView({
    super.key,
    required this.onBack,
    required this.onAddFriend,
  });

  @override
  State<FriendListView> createState() => _FriendListViewState();
}

class _FriendListViewState extends State<FriendListView> {
  bool _isFriendsTabActive = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Mock Friends List
  final List<Map<String, dynamic>> _friends = [
    {
      'name': 'Emma Reyes',
      'username': '@emma_codes',
      'emoji': '👧',
      'bgColor': const Color(0xFF8F93EA),
      'streak': 256,
      'trophies': 457,
    },
    {
      'name': 'Kevin Lim',
      'username': '@kevdev',
      'emoji': '🤓',
      'bgColor': const Color(0xFFFFD56B),
      'streak': 15,
      'trophies': 678,
    },
    {
      'name': 'Bentley Wu',
      'username': '@bentley_w',
      'emoji': '🧒',
      'bgColor': const Color(0xFF8CEEAD),
      'streak': 139,
      'trophies': 102,
    },
  ];

  // Mock Pending Requests List
  final List<Map<String, dynamic>> _requests = [
    {
      'name': 'Sophia Cruz',
      'username': '@sophia_c',
      'emoji': '👩‍💻',
      'bgColor': const Color(0xFFFFB5E8),
    },
    {
      'name': 'Lucas Reyes',
      'username': '@lucas_l',
      'emoji': '👦',
      'bgColor': const Color(0xFFBFFCC6),
    },
    {
      'name': 'Olivia Lim',
      'username': '@olivia_o',
      'emoji': '👧',
      'bgColor': const Color(0xFFFFC5A5),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // Filter lists based on search query
    final filteredFriends = _friends.where((f) {
      return f['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f['username'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredRequests = _requests.where((r) {
      return r['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r['username'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2), // Premium sky blue
      body: Stack(
        children: [
          // 1. Background Silhouettes
          _buildBackgroundDecor(statusBarHeight),

          // 2. Top Header (Back Chevron & Title)
          Positioned(
            top: statusBarHeight + 16,
            left: 16,
            right: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                      onPressed: widget.onBack,
                    ),
                  ),
                ),
                Text(
                  "Friend List",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),

          // 3. Main Content Card Container
          Positioned(
            top: statusBarHeight + 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA), // Light grey/blue container background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120), // Padding below for bottom floating nav
                  children: [
                    // Search & Add Row
                    _buildSearchRow(),
                    const SizedBox(height: 24),

                    // Toggle Tabs (Friends vs Request)
                    _buildToggleTabBar(),
                    const SizedBox(height: 24),

                    // Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        _isFriendsTabActive ? "My Friends" : "Friend Requests",
                        style: GoogleFonts.nunito(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active List display
                    if (_isFriendsTabActive) ...[
                      if (filteredFriends.isEmpty)
                        _buildEmptyState("No friends found.")
                      else
                        ...filteredFriends.map((f) => _buildFriendCard(f)),
                    ] else ...[
                      if (filteredRequests.isEmpty)
                        _buildEmptyState("No pending requests.")
                      else
                        ...filteredRequests.map((r) => _buildRequestCard(r)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating background silhouettes for premium look
  Widget _buildBackgroundDecor(double statusBarHeight) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: statusBarHeight + 10,
            left: 20,
            child: Icon(
              Icons.code_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 50,
            right: 40,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 90,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  // Row with search input and 3D Add button
  Widget _buildSearchRow() {
    return Row(
      children: [
        // Search Input Bar
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Colors.black.withValues(alpha: 0.3),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: GoogleFonts.nunito(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search by username",
                      hintStyle: GoogleFonts.nunito(
                        color: Colors.black.withValues(alpha: 0.25),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 3D Add Button
        Duo3dMiniButton(
          onPressed: widget.onAddFriend,
          faceColor: const Color(0xFFFFB020),
          shadowColor: const Color(0xFFD88900),
          width: 84,
          height: 48,
          child: Text(
            "Add",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  // Toggle button bar: Friends vs Requests
  Widget _buildToggleTabBar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAECEF),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Row(
        children: [
          // Friends tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isFriendsTabActive = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: _isFriendsTabActive ? const Color(0xFF8F93EA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: _isFriendsTabActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8F93EA).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  "Friends",
                  style: GoogleFonts.nunito(
                    color: _isFriendsTabActive ? Colors.white : AppColors.textGrey,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          // Request tab with red circle badge
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isFriendsTabActive = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: !_isFriendsTabActive ? const Color(0xFF8F93EA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: !_isFriendsTabActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8F93EA).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Request",
                      style: GoogleFonts.nunito(
                        color: !_isFriendsTabActive ? Colors.white : AppColors.textGrey,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (_requests.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _requests.length.toString(),
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Text(
          msg,
          style: GoogleFonts.nunito(
            color: AppColors.textGrey,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Row card representing an active friend
  Widget _buildFriendCard(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: friend['bgColor'],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              friend['emoji'],
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 14),

          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'],
                  style: GoogleFonts.nunito(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  friend['username'],
                  style: GoogleFonts.nunito(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                // Stats Row
                Row(
                  children: [
                    // Streak Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text("🔥", style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            friend['streak'].toString(),
                            style: GoogleFonts.nunito(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Trophy Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text("🏆", style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            friend['trophies'].toString(),
                            style: GoogleFonts.nunito(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3D Challenge button
          Duo3dMiniButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Challenged ${friend['name']} to a coding duel!",
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            faceColor: const Color(0xFF8F93EA), // Purple face color
            shadowColor: const Color(0xFF7076E3), // Darker shadow
            width: 90,
            height: 38,
            borderRadius: 19,
            child: Text(
              "Challenge",
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Row card representing a pending request
  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: request['bgColor'],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              request['emoji'],
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['name'],
                  style: GoogleFonts.nunito(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  request['username'],
                  style: GoogleFonts.nunito(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Accept / Decline Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decline Button (gray 3D)
              Duo3dMiniButton(
                onPressed: () {
                  setState(() {
                    _requests.remove(request);
                  });
                },
                faceColor: const Color(0xFFE2E4E8),
                shadowColor: const Color(0xFFC2C5CC),
                width: 38,
                height: 38,
                borderRadius: 19,
                child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 8),
              // Accept Button (green 3D)
              Duo3dMiniButton(
                onPressed: () {
                  setState(() {
                    _requests.remove(request);
                    // Add to friends list with default stats
                    _friends.add({
                      'name': request['name'],
                      'username': request['username'],
                      'emoji': request['emoji'],
                      'bgColor': request['bgColor'],
                      'streak': 0,
                      'trophies': 0,
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Accepted request from ${request['name']}!",
                        style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                faceColor: const Color(0xFF46B830), // Green face
                shadowColor: const Color(0xFF339320), // Dark green shadow
                width: 38,
                height: 38,
                borderRadius: 19,
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- MINI 3D RECT BUTTON ----------------

class Duo3dMiniButton extends StatefulWidget {
  final Widget child;
  final Color faceColor;
  final Color shadowColor;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double borderRadius;

  const Duo3dMiniButton({
    super.key,
    required this.child,
    required this.faceColor,
    required this.shadowColor,
    required this.onPressed,
    required this.width,
    required this.height,
    this.borderRadius = 24,
  });

  @override
  State<Duo3dMiniButton> createState() => _Duo3dMiniButtonState();
}

class _Duo3dMiniButtonState extends State<Duo3dMiniButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 4.0;
    final double translation = _isPressed ? shadowHeight : 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: widget.width,
        height: widget.height + shadowHeight,
        decoration: BoxDecoration(
          color: widget.shadowColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              top: translation,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.faceColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
