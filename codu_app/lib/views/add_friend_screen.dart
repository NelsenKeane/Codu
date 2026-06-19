import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AddFriendView extends StatefulWidget {
  final VoidCallback onBack;

  const AddFriendView({super.key, required this.onBack});

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Recommended friends mock data
  final List<Map<String, dynamic>> _recommendedFriends = [
    {
      'id': 'rf-1',
      'name': 'Emma Reyes',
      'username': '@emma_codes',
      'emoji': '👧',
      'bgColor': const Color(0xFF8F93EA),
      'isAdded': false,
    },
    {
      'id': 'rf-2',
      'name': 'Kevin Lim',
      'username': '@kevdev',
      'emoji': '🤓',
      'bgColor': const Color(0xFFFFD56B),
      'isAdded': false,
    },
    {
      'id': 'rf-3',
      'name': 'Brandon Cruz',
      'username': '@brandon_c',
      'emoji': '👦',
      'bgColor': const Color(0xFFFF8B8B),
      'isAdded': false,
    },
    {
      'id': 'rf-4',
      'name': 'Bentley Wu',
      'username': '@bentley_w',
      'emoji': '🧒',
      'bgColor': const Color(0xFF8CEEAD),
      'isAdded': false,
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

    // Filter recommended friends list based on search query
    final filteredFriends = _recommendedFriends.where((friend) {
      final nameMatches = friend['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      final usernameMatches = friend['username'].toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || usernameMatches;
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
                  "Add friend",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),

          // 3. Main Content Card
          Positioned(
            top: statusBarHeight + 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA), // Off-white card container from mockup
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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  children: [
                    // Search by Username Input Field
                    _buildSearchBar(),
                    const SizedBox(height: 28),

                    // "Recommended" Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        "Recommended",
                        style: GoogleFonts.nunito(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recommended Grid (2x2 layout)
                    if (filteredFriends.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "No users found matching your search.",
                            style: GoogleFonts.nunito(
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      _buildRecommendedGrid(filteredFriends),
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

  // Rounded search bar input
  Widget _buildSearchBar() {
    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.black.withValues(alpha: 0.3),
            size: 24,
          ),
          const SizedBox(width: 10),
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
    );
  }

  // Custom 2-column Grid of user cards
  Widget _buildRecommendedGrid(List<Map<String, dynamic>> list) {
    List<Widget> rows = [];
    for (int i = 0; i < list.length; i += 2) {
      Widget leftCard = _buildFriendCard(list[i]);
      Widget rightCard = (i + 1 < list.length)
          ? _buildFriendCard(list[i + 1])
          : Expanded(child: Container());

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(child: leftCard),
              const SizedBox(width: 16),
              Expanded(child: rightCard),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  // Individual Friend card with custom 3D Add button
  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final bool isAdded = friend['isAdded'];

    return Container(
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Avatar
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: friend['bgColor'],
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF0F2F6), width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              friend['emoji'],
              style: const TextStyle(fontSize: 42),
            ),
          ),
          const SizedBox(height: 14),

          // Display Name
          Text(
            friend['name'],
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),

          // Username
          Text(
            friend['username'],
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textGrey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // 3D Add / Requested Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: isAdded
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8E9), // Light green requested state
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: const Color(0xFF46B830), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded, color: Color(0xFF46B830), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Requested",
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF46B830),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Duo3dAddButton(
                    onPressed: () {
                      setState(() {
                        friend['isAdded'] = true;
                      });
                    },
                    faceColor: const Color(0xFFFFB020),
                    shadowColor: const Color(0xFFD88900),
                    child: Text(
                      "Add",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------- MINI 3D RECT BUTTON FOR CARD ----------------

class Duo3dAddButton extends StatefulWidget {
  final Widget child;
  final Color faceColor;
  final Color shadowColor;
  final VoidCallback onPressed;

  const Duo3dAddButton({
    super.key,
    required this.child,
    required this.faceColor,
    required this.shadowColor,
    required this.onPressed,
  });

  @override
  State<Duo3dAddButton> createState() => _Duo3dAddButtonState();
}

class _Duo3dAddButtonState extends State<Duo3dAddButton> {
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
        decoration: BoxDecoration(
          color: widget.shadowColor,
          borderRadius: BorderRadius.circular(19),
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
                  borderRadius: BorderRadius.circular(19),
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
