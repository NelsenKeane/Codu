import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/friend_service.dart';

class AddFriendView extends StatefulWidget {
  final VoidCallback onBack;

  const AddFriendView({super.key, required this.onBack});

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  List<Map<String, dynamic>> _recommendations = [];
  bool _loadingRecommendations = true;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Track statuses locally to give immediate feedback when tapping "Add"
  final Map<String, String> _statuses = {};

  final List<Map<String, dynamic>> _avatars = [
    {'emoji': '🤓', 'bgColor': const Color(0xFFFFD56B), 'name': 'Nerd Boy'},
    {'emoji': '👧', 'bgColor': const Color(0xFF8F93EA), 'name': 'Long Hair Girl'},
    {'emoji': '👦', 'bgColor': const Color(0xFFFF8B8B), 'name': 'Brandon'},
    {'emoji': '👩‍💼', 'bgColor': const Color(0xFFFFC5A5), 'name': 'Emma'},
    {'emoji': '🧒', 'bgColor': const Color(0xFF7A9EFF), 'name': 'Curly Boy'},
    {'emoji': '🧒', 'bgColor': const Color(0xFF8CEEAD), 'name': 'Bentley'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final snap = await FirebaseFirestore.instance.collection('users').limit(20).get();
      
      final List<Map<String, dynamic>> loadedList = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['uid'] == currentUid) continue;

        // Fetch relationship status
        final status = await FriendService().getFriendshipStatus(data['uid']);
        // Recommend users who are not yet friends and don't have pending request
        if (status == 'none') {
          loadedList.add(data);
          _statuses[data['uid']] = status;
        }
      }

      if (mounted) {
        setState(() {
          _recommendations = loadedList.take(6).toList(); // Show up to 6 recommended users
          _loadingRecommendations = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading recommendations: $e");
      if (mounted) {
        setState(() {
          _loadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim().replaceAll('@', '').toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await FriendService().searchUsers(cleanQuery);
      for (var user in results) {
        final uid = user['uid'];
        if (uid != null && !_statuses.containsKey(uid)) {
          final status = await FriendService().getFriendshipStatus(uid);
          _statuses[uid] = status;
        }
      }
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _sendRequest(String targetUid) async {
    try {
      await FriendService().sendFriendRequest(targetUid);
      setState(() {
        _statuses[targetUid] = 'outgoing';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Friend request sent!",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error sending request: $e");
    }
  }

  Future<void> _acceptRequest(String targetUid) async {
    try {
      await FriendService().acceptFriendRequest(targetUid);
      setState(() {
        _statuses[targetUid] = 'friend';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Accepted friend request!",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error accepting request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2),
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/codu_background_pattern_mobile_soft.svg',
              fit: BoxFit.cover,
            ),
          ),
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
                color: Color(0xFFF7F8FA),
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

                    // Search Results or Recommendations
                    if (_searchQuery.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          "Search Results",
                          style: GoogleFonts.nunito(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isSearching)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: Color(0xFF56CCF2)),
                          ),
                        )
                      else if (_searchResults.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "No users found matching \"$_searchQuery\"",
                              style: GoogleFonts.nunito(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        _buildRecommendedGrid(_searchResults),
                    ] else ...[
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

                      if (_loadingRecommendations)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: Color(0xFF56CCF2)),
                          ),
                        )
                      else if (_recommendations.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "No recommendations right now.",
                              style: GoogleFonts.nunito(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildRecommendedGrid(_recommendations),
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
                _performSearch(val);
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
    final uid = friend['uid'] ?? "";
    final currentStatus = _statuses[uid] ?? 'none';
    final avatarIndex = friend['avatarIndex'] ?? 0;
    final Map<String, dynamic> avatar = (avatarIndex >= 0 && avatarIndex < _avatars.length)
        ? _avatars[avatarIndex]
        : _avatars[0];

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
              color: avatar['bgColor'],
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF0F2F6), width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              avatar['emoji'],
              style: const TextStyle(fontSize: 42),
            ),
          ),
          const SizedBox(height: 14),

          // Display Name
          Text(
            friend['displayName'] ?? "Codu User",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Username
          Text(
            "@${friend['username'] ?? 'username'}",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.textGrey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // 3D Add / Requested / Friends Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: _buildFriendshipActionButton(uid, currentStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendshipActionButton(String targetUid, String status) {
    if (status == 'outgoing') {
      return Container(
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
      );
    } else if (status == 'incoming') {
      return Duo3dAddButton(
        onPressed: () => _acceptRequest(targetUid),
        faceColor: const Color(0xFF46B830), // Green face color to accept
        shadowColor: const Color(0xFF339320),
        child: Text(
          "Accept",
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      );
    } else if (status == 'friend') {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF1),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFF90A4AE), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_rounded, color: Color(0xFF78909C), size: 16),
            const SizedBox(width: 4),
            Text(
              "Friends",
              style: GoogleFonts.nunito(
                color: const Color(0xFF78909C),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } else {
      // status == 'none'
      return Duo3dAddButton(
        onPressed: () => _sendRequest(targetUid),
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
      );
    }
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
