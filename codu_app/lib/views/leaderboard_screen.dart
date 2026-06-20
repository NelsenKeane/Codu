import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/user_data_service.dart';
import '../services/friend_service.dart';
import '../widgets/skeleton_loader.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isGlobalSelected = true;
  bool _isLoading = true;
  int _userTrophies = 0;

  List<Map<String, dynamic>> _globalRankings = [];
  List<Map<String, dynamic>> _friendsRankings = [];

  final List<Map<String, dynamic>> _avatars = [
    {'svgPath': 'assets/images/Characters/Female1.svg', 'bgColor': const Color(0xFFFFD56B), 'name': 'Female 1'},
    {'svgPath': 'assets/images/Characters/Female2.svg', 'bgColor': const Color(0xFF8F93EA), 'name': 'Female 2'},
    {'svgPath': 'assets/images/Characters/Female3.svg', 'bgColor': const Color(0xFFFF8B8B), 'name': 'Female 3'},
    {'svgPath': 'assets/images/Characters/Male1.svg', 'bgColor': const Color(0xFFFFC5A5), 'name': 'Male 1'},
    {'svgPath': 'assets/images/Characters/Male2.svg', 'bgColor': const Color(0xFF7A9EFF), 'name': 'Male 2'},
    {'svgPath': 'assets/images/Characters/Male3.svg', 'bgColor': const Color(0xFF8CEEAD), 'name': 'Male 3'},
  ];

  @override
  void initState() {
    super.initState();
    _syncAndLoadLeaderboard();
  }

  Future<void> _syncAndLoadLeaderboard() async {
    // 1. Sync current user to Firestore
    await FriendService().syncUserToFirestore().catchError((e) {
      debugPrint("Failed to sync user on leaderboard: $e");
    });

    // 2. Load current trophies count
    final trophies = await UserDataService().getTrophies();
    if (mounted) {
      setState(() {
        _userTrophies = trophies;
      });
    }

    // 3. Fetch rankings
    await _loadRankings();
  }

  Future<void> _loadRankings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final globalList = await _fetchGlobalRankings();
      final friendsList = await _fetchFriendsRankings();

      if (mounted) {
        setState(() {
          _globalRankings = globalList;
          _friendsRankings = friendsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading rankings: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGlobalRankings() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('trophies', descending: true)
        .limit(50)
        .get();

    List<Map<String, dynamic>> list = [];
    int rank = 1;
    for (var doc in snap.docs) {
      final data = doc.data();
      final uid = doc.id;
      list.add({
        'uid': uid,
        'rank': rank++,
        'name': data['displayName'] ?? "Student",
        'score': data['trophies'] ?? 0,
        'avatarIndex': data['avatarIndex'] ?? 0,
        'isSelf': uid == currentUid,
      });
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> _fetchFriendsRankings() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return [];

    // Get friend UIDs
    final friendsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .get();

    List<String> friendUids = friendsSnap.docs.map((d) => d.id).toList();
    // Include current user
    friendUids.add(currentUid);

    List<Map<String, dynamic>> friendProfiles = [];

    // Fetch user profiles for all UIDs in chunks of 10
    for (int i = 0; i < friendUids.length; i += 10) {
      final chunk = friendUids.sublist(i, min(i + 10, friendUids.length));
      final profilesSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', whereIn: chunk)
          .get();
      for (var doc in profilesSnap.docs) {
        friendProfiles.add(doc.data());
      }
    }

    // Sort by trophies descending
    friendProfiles.sort((a, b) {
      final int tA = a['trophies'] ?? 0;
      final int tB = b['trophies'] ?? 0;
      return tB.compareTo(tA);
    });

    // Assign ranks
    List<Map<String, dynamic>> list = [];
    int rank = 1;
    for (var profile in friendProfiles) {
      final uid = profile['uid'];
      list.add({
        'uid': uid,
        'rank': rank++,
        'name': profile['displayName'] ?? "Student",
        'score': profile['trophies'] ?? 0,
        'avatarIndex': profile['avatarIndex'] ?? 0,
        'isSelf': uid == currentUid,
      });
    }
    return list;
  }

  Widget _buildLeaderboardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F6),
              borderRadius: BorderRadius.circular(27),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  const SkeletonLoader(width: 55, height: 55, borderRadius: BorderRadius.all(Radius.circular(27.5))),
                  const SizedBox(height: 10),
                  Container(
                    width: 75,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const SkeletonLoader(width: 60, height: 60, borderRadius: BorderRadius.all(Radius.circular(30))),
                  const SizedBox(height: 10),
                  Container(
                    width: 75,
                    height: 135,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const SkeletonLoader(width: 50, height: 50, borderRadius: BorderRadius.all(Radius.circular(25))),
                  const SizedBox(height: 10),
                  Container(
                    width: 75,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E5E5), thickness: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      const SkeletonLoader(width: 25, height: 25, borderRadius: BorderRadius.all(Radius.circular(6))),
                      const SizedBox(width: 16),
                      const SkeletonLoader(width: 38, height: 38, borderRadius: BorderRadius.all(Radius.circular(19))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: const SkeletonLoader(width: 100, height: 16),
                      ),
                      const SizedBox(width: 16),
                      const SkeletonLoader(width: 45, height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final List<Map<String, dynamic>> rankings = _isGlobalSelected ? _globalRankings : _friendsRankings;

    // Separate podium (top 3) from the scrollable list below (ranks 4+)
    final List<Map<String, dynamic>> topThree = rankings.where((r) => r['rank'] <= 3).toList();
    final List<Map<String, dynamic>> remainingList = rankings.where((r) => r['rank'] > 3).toList();

    // Sort podium so order is 2nd (left), 1st (middle), 3rd (right)
    Map<String, dynamic> firstPlace = topThree.firstWhere(
      (r) => r['rank'] == 1,
      orElse: () => {'rank': 1, 'name': '-', 'score': 0, 'avatarIndex': 0, 'isEmpty': true},
    );
    Map<String, dynamic> secondPlace = topThree.firstWhere(
      (r) => r['rank'] == 2,
      orElse: () => {'rank': 2, 'name': '-', 'score': 0, 'avatarIndex': 0, 'isEmpty': true},
    );
    Map<String, dynamic> thirdPlace = topThree.firstWhere(
      (r) => r['rank'] == 3,
      orElse: () => {'rank': 3, 'name': '-', 'score': 0, 'avatarIndex': 0, 'isEmpty': true},
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackgroundDecor(statusBarHeight),

          Positioned(
            top: statusBarHeight + 16,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Leaderboard",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                _buildTrophyScoreCapsule(),
              ],
            ),
          ),

          Positioned(
            top: statusBarHeight + 84,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
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
                child: _isLoading
                    ? _buildLeaderboardSkeleton()
                    : RefreshIndicator(
                        onRefresh: _syncAndLoadLeaderboard,
                        color: const Color(0xFF8F93EA),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                          children: [
                            _buildTabSelector(),
                            const SizedBox(height: 24),

                            _buildPodium(secondPlace, firstPlace, thirdPlace),
                            const SizedBox(height: 24),

                            const Divider(
                              height: 1,
                              color: Color(0xFFE5E5E5),
                              thickness: 1,
                            ),
                            const SizedBox(height: 16),

                            if (remainingList.isEmpty) ...[
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  _isGlobalSelected
                                      ? "No global players found"
                                      : "No friends in leaderboard yet",
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else
                              ...remainingList.map((player) => _buildPlayerRankCard(player)),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor(double statusBarHeight) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: statusBarHeight + 10,
            left: 30,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 70,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 50,
            right: 110,
            child: Icon(
              Icons.code_rounded,
              size: 50,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyScoreCapsule() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF3F4D59),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "🏆",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            "$_userTrophies",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isGlobalSelected = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isGlobalSelected ? const Color(0xFF8F93EA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: _isGlobalSelected
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
                    Icon(
                      Icons.public_rounded,
                      color: _isGlobalSelected ? Colors.white : const Color(0xFF8F9BB3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Global",
                      style: GoogleFonts.nunito(
                        color: _isGlobalSelected ? Colors.white : const Color(0xFF8F9BB3),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isGlobalSelected = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !_isGlobalSelected ? const Color(0xFF8F93EA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: !_isGlobalSelected
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
                    Icon(
                      Icons.people_alt_rounded,
                      color: !_isGlobalSelected ? Colors.white : const Color(0xFF8F9BB3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Friends",
                      style: GoogleFonts.nunito(
                        color: !_isGlobalSelected ? Colors.white : const Color(0xFF8F9BB3),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(
    Map<String, dynamic> second,
    Map<String, dynamic> first,
    Map<String, dynamic> third,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPodiumColumn(
          player: second,
          podiumHeight: 135,
          columnColor: const Color(0xFF8F93EA),
          badgeBorderColor: const Color(0xFFB0B0B0),
          badgeFillColor: const Color(0xFFCCCCCC),
        ),
        const SizedBox(width: 12),
        _buildPodiumColumn(
          player: first,
          podiumHeight: 175,
          columnColor: const Color(0xFF8F93EA),
          badgeBorderColor: const Color(0xFFD97E00),
          badgeFillColor: const Color(0xFFFFC043),
        ),
        const SizedBox(width: 12),
        _buildPodiumColumn(
          player: third,
          podiumHeight: 110,
          columnColor: const Color(0xFF8F93EA),
          badgeBorderColor: const Color(0xFF8E5A2A),
          badgeFillColor: const Color(0xFFCD7F32),
        ),
      ],
    );
  }

  Widget _buildPodiumColumn({
    required Map<String, dynamic> player,
    required double podiumHeight,
    required Color columnColor,
    required Color badgeBorderColor,
    required Color badgeFillColor,
  }) {
    final bool isEmpty = player['isEmpty'] == true;
    final bool isSelf = player['isSelf'] ?? false;

    Color avatarBgColor = const Color(0xFFE2E8F0);
    Widget avatarChild = const Icon(
      Icons.person_rounded,
      color: Color(0xFF94A3B8),
      size: 38,
    );

    if (!isEmpty) {
      final int avatarIndex = player['avatarIndex'] ?? 0;
      final avatar = _avatars[avatarIndex.clamp(0, 5)];
      avatarBgColor = avatar['bgColor'];
      avatarChild = ClipOval(
        child: Transform.scale(
          scale: 1.2,
          child: SvgPicture.asset(
            avatar['svgPath'],
            width: 68,
            height: 68,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: avatarBgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelf ? const Color(0xFFFFD56B) : Colors.white,
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: avatarChild,
        ),
        const SizedBox(height: 10),
        Container(
          width: 90,
          height: podiumHeight,
          decoration: BoxDecoration(
            color: columnColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: columnColor.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildRankBadge(player['rank'] as int, size: 30),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  player['name'],
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "🏆",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    player['score'].toString(),
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRankCard(Map<String, dynamic> player) {
    final bool isSelf = player['isSelf'] ?? false;
    final int avatarIndex = player['avatarIndex'] ?? 0;
    final avatar = _avatars[avatarIndex.clamp(0, 5)];
    final Color bgColor = avatar['bgColor'];
    final String svgPath = avatar['svgPath'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelf ? const Color(0xFFFFFBEA) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelf ? const Color(0xFFFFD56B) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildRankBadge(player['rank'] as int, size: 30),
          const SizedBox(width: 16),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: ClipOval(
              child: Transform.scale(
                scale: 1.2,
                child: SvgPicture.asset(
                  svgPath,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Text(
              player['name'],
              style: GoogleFonts.nunito(
                color: const Color(0xFF2B2D42),
                fontWeight: isSelf ? FontWeight.w900 : FontWeight.w800,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🏆",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                player['score'].toString(),
                style: GoogleFonts.nunito(
                  color: const Color(0xFF2B2D42),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank, {double size = 32}) {
    if (rank == 1) {
      return SvgPicture.asset(
        'assets/images/Rank1_Icon.svg',
        width: size,
        height: size * 1.125,
      );
    } else if (rank == 2) {
      return SvgPicture.asset(
        'assets/images/Rank2_Icon.svg',
        width: size,
        height: size * 1.125,
      );
    } else if (rank == 3) {
      return SvgPicture.asset(
        'assets/images/Rank3_Icon.svg',
        width: size,
        height: size * 1.125,
      );
    } else {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/Rank4_Icon.svg',
              width: size,
              height: size,
            ),
            Text(
              rank.toString(),
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.44,
              ),
            ),
          ],
        ),
      );
    }
  }
}
