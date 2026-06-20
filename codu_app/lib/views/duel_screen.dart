import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_models.dart';
import '../services/user_data_service.dart';
import '../widgets/duo_3d_button.dart';

enum DuelState {
  lobby,
  searching,
  matchFound,
  gameplay,
  results,
}

class DuelScreen extends StatefulWidget {
  final Function(bool showBottomBar)? onShowBottomBarChanged;
  const DuelScreen({super.key, this.onShowBottomBarChanged});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> with TickerProviderStateMixin {
  DuelState _currentState = DuelState.lobby;

  // User details
  String _displayName = "Alex";
  int _trophies = 150;
  int _avatarIndex = 0;

  // Opponent details (Simulated Erica)
  final String _opponentName = "Erica";
  final int _opponentAvatarIndex = 2; // Female3 (matches user image)
  final int _opponentTrophies = 155;

  // Matchmaking variables
  Timer? _searchTimer;
  int _searchSeconds = 0;

  // Match found countdown
  Timer? _countdownTimer;
  int _countdownSeconds = 5;

  // Gameplay variables
  late List<CodingQuestion> _questions;
  int _currentQuestionIndex = 0;
  int _userScore = 0;
  int _opponentScore = 0;
  bool _isAnswerChecked = false;
  bool _isAnswerCorrect = false;
  final Map<String, int?> _slotContents = {};

  // Opponent simulation timers
  Timer? _opponentActionTimer;
  int _opponentQuestionsAnswered = 0;

  // Result variable
  int _trophyDelta = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _radialController;

  // Avatars mapping
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
    _loadUserData();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Load Python level 1 questions for the duel
    _questions = QuestionBank.getQuestionsForLevel(1, 'Python').sublist(0, 5);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onShowBottomBarChanged?.call(true);
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _countdownTimer?.cancel();
    _opponentActionTimer?.cancel();
    _pulseController.dispose();
    _radialController.dispose();
    super.dispose();
  }

  void _updateState(DuelState state) {
    if (mounted) {
      setState(() {
        _currentState = state;
      });
      widget.onShowBottomBarChanged?.call(state == DuelState.lobby);
    }
  }

  Future<void> _loadUserData() async {
    final name = await UserDataService().getDisplayName();
    final trophies = await UserDataService().getTrophies();
    final avatar = await UserDataService().getAvatarIndex();
    if (mounted) {
      setState(() {
        if (name != null && name.trim().isNotEmpty) {
          _displayName = name;
        }
        _trophies = trophies;
        _avatarIndex = avatar;
      });
    }
  }

  // --- TRANSITIONS ---

  void _startSearching() {
    _updateState(DuelState.searching);
    setState(() {
      _searchSeconds = 0;
    });

    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _searchSeconds++;
      });
      // Simulate finding a match after 4 seconds
      if (_searchSeconds >= 4) {
        timer.cancel();
        _triggerMatchFound();
      }
    });
  }

  void _cancelSearching() {
    _searchTimer?.cancel();
    _updateState(DuelState.lobby);
  }

  void _triggerMatchFound() {
    _updateState(DuelState.matchFound);
    setState(() {
      _countdownSeconds = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        _startDuelGameplay();
      }
    });
  }

  void _cancelMatchFound() {
    _countdownTimer?.cancel();
    _updateState(DuelState.lobby);
  }

  void _startDuelGameplay() {
    _updateState(DuelState.gameplay);
    setState(() {
      _currentQuestionIndex = 0;
      _userScore = 0;
      _opponentScore = 0;
      _opponentQuestionsAnswered = 0;
    });
    _clearSlots();
    _startOpponentSimulation();
  }

  void _startOpponentSimulation() {
    _opponentActionTimer?.cancel();
    // Opponent Erica answers a question every 6 to 10 seconds
    final Random rand = Random();
    
    _scheduleNextOpponentAction(rand);
  }

  void _scheduleNextOpponentAction(Random rand) {
    if (_currentState != DuelState.gameplay) return;
    
    final delaySeconds = rand.nextInt(5) + 6; // 6 to 10 seconds
    
    _opponentActionTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_currentState != DuelState.gameplay) return;

      setState(() {
        _opponentQuestionsAnswered++;
        // 80% chance Erica gets it correct (+20 points)
        if (rand.nextDouble() < 0.8) {
          _opponentScore += 20;
        }
      });

      if (_opponentQuestionsAnswered < 5) {
        _scheduleNextOpponentAction(rand);
      } else {
        // Opponent finished
        _checkDuelCompletion();
      }
    });
  }

  void _clearSlots() {
    _slotContents.clear();
    final question = _questions[_currentQuestionIndex];
    for (var line in question.codeLines) {
      for (var segment in line) {
        if (segment.isSlot) {
          _slotContents[segment.text] = null;
        }
      }
    }
    _isAnswerChecked = false;
  }

  void _handleChoiceTap(int choiceIndex) {
    if (_isAnswerChecked) return;

    final question = _questions[_currentQuestionIndex];

    // Check if it's already placed
    String? alreadyPlacedSlot;
    _slotContents.forEach((key, value) {
      if (value == choiceIndex) {
        alreadyPlacedSlot = key;
      }
    });

    if (alreadyPlacedSlot != null) {
      setState(() {
        _slotContents[alreadyPlacedSlot!] = null;
      });
    } else {
      // Find first empty slot
      String? firstEmptySlot;
      for (var line in question.codeLines) {
        for (var segment in line) {
          if (segment.isSlot && _slotContents[segment.text] == null) {
            firstEmptySlot = segment.text;
            break;
          }
        }
        if (firstEmptySlot != null) break;
      }

      if (firstEmptySlot != null) {
        setState(() {
          _slotContents[firstEmptySlot!] = choiceIndex;
        });
      }
    }
  }

  void _onCheckAnswer() {
    if (_isAnswerChecked) return;

    final question = _questions[_currentQuestionIndex];

    // Check if all slots filled
    bool allFilled = true;
    _slotContents.forEach((key, value) {
      if (value == null) allFilled = false;
    });

    if (!allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fill all the blanks first!"),
          backgroundColor: Color(0xFFFFB020),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Evaluate
    bool correct = true;
    _slotContents.forEach((slotId, valueIndex) {
      if (valueIndex == null) {
        correct = false;
      } else {
        final choiceValue = question.choices[valueIndex];
        if (question.correctAnswers[slotId] != choiceValue) {
          correct = false;
        }
      }
    });

    setState(() {
      _isAnswerChecked = true;
      _isAnswerCorrect = correct;
      if (correct) {
        _userScore += 20; // +20 points for correct
      }
    });
  }

  void _onContinueGameplay() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _clearSlots();
      });
    } else {
      // User finished all questions!
      _checkDuelCompletion();
    }
  }

  void _checkDuelCompletion() {
    final bool userFinished = _currentQuestionIndex >= 4 && _isAnswerChecked;
    final bool opponentFinished = _opponentQuestionsAnswered >= 5;

    if (userFinished && opponentFinished) {
      _endDuel();
    } else if (userFinished && !opponentFinished) {
      // Fast-forward opponent remaining questions so user doesn't wait long
      _opponentActionTimer?.cancel();
      final Random rand = Random();
      
      _opponentActionTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (_currentState != DuelState.gameplay) {
          timer.cancel();
          return;
        }
        setState(() {
          _opponentQuestionsAnswered++;
          if (rand.nextDouble() < 0.8) {
            _opponentScore += 20;
          }
        });

        if (_opponentQuestionsAnswered >= 5) {
          timer.cancel();
          _endDuel();
        }
      });
    }
  }

  Future<void> _endDuel() async {
    _opponentActionTimer?.cancel();

    // Determine trophy changes
    int delta = 0;
    if (_userScore > _opponentScore) {
      delta = 30; // Win
    } else if (_userScore < _opponentScore) {
      delta = -15; // Lose
    } else {
      delta = 5; // Draw reward
    }

    int newTrophies = max(0, _trophies + delta);
    await UserDataService().saveTrophies(newTrophies);

    setState(() {
      _trophyDelta = delta;
    });
    _updateState(DuelState.results);
  }

  Future<bool> _confirmForfeit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Forfeit Duel?",
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: const Color(0xFF1E2A38)),
        ),
        content: Text(
          "Are you sure you want to quit? You will lose 15 trophies for forfeiting.",
          style: GoogleFonts.nunito(color: const Color(0xFF5A6B7C), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Keep Playing",
              style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: const Color(0xFF1D83B5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Forfeit",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _forfeitMatch() async {
    _opponentActionTimer?.cancel();
    int newTrophies = max(0, _trophies - 15);
    await UserDataService().saveTrophies(newTrophies);
    setState(() {
      _trophyDelta = -15;
      _userScore = 0;
      _opponentScore = 100;
    });
    _updateState(DuelState.results);
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case DuelState.lobby:
        return _buildLobbyView();
      case DuelState.searching:
        return _buildSearchingView();
      case DuelState.matchFound:
        return _buildMatchFoundView();
      case DuelState.gameplay:
        return _buildGameplayView();
      case DuelState.results:
        return _buildResultsView();
    }
  }

  // 1. Lobby View
  Widget _buildLobbyView() {
    return Container(
      color: const Color(0xFFF0F2F6),
      child: Stack(
        children: [
          // Background soft pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: SvgPicture.asset(
                'assets/images/codu_background_pattern_mobile_soft.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Controller 3D/Premium Logo card
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F80ED).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      "Python Coding Duel",
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF1E2A38),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Test your speed and accuracy against online developers!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF9AAEC4),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Trophy Box (curated theme)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "🏆",
                            style: TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "YOUR TROPHIES",
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF9AAEC4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                "$_trophies",
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF1E2A38),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Find Match 3D Button
                    SizedBox(
                      width: 240,
                      child: Duo3dButton(
                        faceColor: const Color(0xFFFFB020),
                        shadowColor: const Color(0xFFD88900),
                        height: 56,
                        borderRadius: 28,
                        onPressed: _startSearching,
                        child: Text(
                          "FIND MATCH",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Bottom navigation offset
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Searching/Matchmaking View
  Widget _buildSearchingView() {
    return Container(
      color: const Color(0xFFF0F2F6),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: SvgPicture.asset(
                'assets/images/codu_background_pattern_mobile_soft.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spinning Radar Matchmaking Visual
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing outer ring
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.5).animate(_pulseController),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.4, end: 0.0).animate(_pulseController),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF56CCF2), width: 3),
                              ),
                            ),
                          ),
                        ),
                        // Spinning line circle
                        RotationTransition(
                          turns: _radialController,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  const Color(0xFF56CCF2).withValues(alpha: 0.1),
                                  const Color(0xFF56CCF2),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Inner solid circle with search icon
                        Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.youtube_searched_for_rounded,
                            color: Color(0xFF2F80ED),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Status text
                    Text(
                      "Searching for opponent...",
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF1E2A38),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Elapsed timer
                    Text(
                      _formatTimer(_searchSeconds),
                      style: GoogleFonts.firaCode(
                        color: const Color(0xFF9AAEC4),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Estimated wait time: < 10s",
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF9AAEC4),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Cancel Button
                    SizedBox(
                      width: 180,
                      child: Duo3dButton(
                        faceColor: const Color(0xFFE55353),
                        shadowColor: const Color(0xFFB83C3C),
                        height: 48,
                        borderRadius: 24,
                        onPressed: _cancelSearching,
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Match Found View (Countdown)
  Widget _buildMatchFoundView() {
    final Map<String, dynamic> activeAvatar = _avatars[_avatarIndex];
    final Map<String, dynamic> opponentAvatar = _avatars[_opponentAvatarIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF4AC4FF),
      body: Stack(
        children: [
          // Background soft pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: SvgPicture.asset(
                'assets/images/codu_background_pattern_mobile_soft.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Back Button (cancels match)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 26),
                      onPressed: _cancelMatchFound,
                    ),
                  ),
                ),
                const Spacer(flex: 1),

                // Match Found Title
                Text(
                  "Match Found!",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(flex: 2),

                // Players Cards (Vertical stack like Clash Royale)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      // Player 1 Card (User)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: activeAvatar['bgColor'],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                  ),
                                  child: ClipOval(
                                    child: Transform.scale(
                                      scale: 1.2,
                                      child: SvgPicture.asset(
                                        activeAvatar['svgPath'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Name & Trophies
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _displayName,
                                      style: GoogleFonts.nunito(
                                        color: const Color(0xFF1E2A38),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Text("🏆", style: TextStyle(fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Text(
                                            "$_trophies",
                                            style: GoogleFonts.nunito(
                                              color: const Color(0xFF9B51E0),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
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
                          // "You" badge
                          Positioned(
                            top: -10,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9B51E0),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "You",
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // VS Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        child: Text(
                          "VS",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      // Player 2 Card (Opponent - Erica)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: opponentAvatar['bgColor'],
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                              ),
                              child: ClipOval(
                                child: Transform.scale(
                                  scale: 1.2,
                                  child: SvgPicture.asset(
                                    opponentAvatar['svgPath'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Name & Trophies
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _opponentName,
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFF1E2A38),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text("🏆", style: TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(
                                        "$_opponentTrophies",
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF9B51E0),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
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
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Countdown info
                Text(
                  "Match starts in $_countdownSeconds seconds",
                  style: GoogleFonts.nunito(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Cancel match Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Duo3dButton(
                    faceColor: const Color(0xFFFFB020),
                    shadowColor: const Color(0xFFD88900),
                    height: 52,
                    borderRadius: 26,
                    onPressed: _cancelMatchFound,
                    child: Text(
                      "Cancel match",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Gameplay View
  Widget _buildGameplayView() {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex) / _questions.length;
    final Map<String, dynamic> activeAvatar = _avatars[_avatarIndex];
    final Map<String, dynamic> opponentAvatar = _avatars[_opponentAvatarIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmForfeit();
        if (shouldPop && mounted) {
          _forfeitMatch();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4AC4FF),
        body: Stack(
          children: [
            // Soft Background Pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: SvgPicture.asset(
                  'assets/images/codu_background_pattern_mobile_soft.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // --- DUEL HEADER ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 26),
                              onPressed: () async {
                                final shouldPop = await _confirmForfeit();
                                if (shouldPop && mounted) {
                                  _forfeitMatch();
                                }
                              },
                            ),
                            const Expanded(child: SizedBox()),
                            Text(
                              "Phyton Quizz",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                            const SizedBox(width: 48), // Spacer balance
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Side-by-Side Avatars and Scores
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // User (Alex)
                            Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: activeAvatar['bgColor'],
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                      ),
                                      child: ClipOval(
                                        child: Transform.scale(
                                          scale: 1.2,
                                          child: SvgPicture.asset(
                                            activeAvatar['svgPath'],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Score badge (Gold/Orange)
                                    Positioned(
                                      top: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFB020),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          "$_userScore",
                                          style: GoogleFonts.nunito(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _displayName,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Text(
                              "VS",
                              style: GoogleFonts.nunito(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Opponent (Erica)
                            Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: opponentAvatar['bgColor'],
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                      ),
                                      child: ClipOval(
                                        child: Transform.scale(
                                          scale: 1.2,
                                          child: SvgPicture.asset(
                                            opponentAvatar['svgPath'],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Score badge (Green)
                                    Positioned(
                                      top: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2ECC71),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          "$_opponentScore",
                                          style: GoogleFonts.nunito(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _opponentName,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Sleek Progress Bar
                        Container(
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: constraints.maxWidth * progress,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB020),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- WORKSPACE & CHOICES (WHITE PANEL) ---
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F2F6),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.15,
                              child: SvgPicture.asset(
                                'assets/images/codu_background_pattern_mobile_soft.svg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      // Question Card
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              question.instruction,
                                              style: GoogleFonts.nunito(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF2C3E50),
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            // Code Workspace
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16.0),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFEFEF),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: _buildCodeLines(question),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 28),

                                      // Choices chips
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 12,
                                        alignment: WrapAlignment.center,
                                        children: List.generate(question.choices.length, (index) {
                                          final choice = question.choices[index];

                                          // Check if already placed in workspace
                                          bool isAlreadyPlaced = false;
                                          _slotContents.forEach((key, value) {
                                            if (value == index) isAlreadyPlaced = true;
                                          });

                                          return Draggable<int>(
                                            data: index,
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: _buildChoiceChip(choice, isDragging: true),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.3,
                                              child: _buildChoiceChip(choice, isPlaced: true),
                                            ),
                                            child: GestureDetector(
                                              onTap: () => _handleChoiceTap(index),
                                              child: _buildChoiceChip(choice, isPlaced: isAlreadyPlaced),
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Bottom bar for check & continue
                              _buildBottomActionBar(),
                            ],
                          ),
                          // Simulated match finish loading overlay
                          if (_currentQuestionIndex >= 4 && _isAnswerChecked && _opponentQuestionsAnswered < 5)
                            Container(
                              color: Colors.black.withValues(alpha: 0.6),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                                  margin: const EdgeInsets.symmetric(horizontal: 32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 15),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(
                                        color: Color(0xFFFFB020),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "Waiting for opponent to finish...",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF1E2A38),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Erica is answering question ${_opponentQuestionsAnswered + 1}/5",
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF9AAEC4),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: CodeLines widget
  Widget _buildCodeLines(CodingQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: question.codeLines.map((line) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: line.map((segment) {
              if (segment.isSlot) {
                return _buildSlotTarget(segment.text, segment.placeholder ?? "...");
              } else {
                final String text = segment.text;
                if (text.startsWith("    ")) {
                  final int spacesCount = text.length - text.trimLeft().length;
                  final double indentWidth = (spacesCount / 4) * 20.0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: indentWidth),
                      Text(
                        text.trimLeft(),
                        style: GoogleFonts.firaCode(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334E68),
                        ),
                      ),
                    ],
                  );
                }
                return Text(
                  text,
                  style: GoogleFonts.firaCode(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334E68),
                  ),
                );
              }
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // Helper: Slots
  Widget _buildSlotTarget(String slotId, String placeholder) {
    final int? placedIndex = _slotContents[slotId];
    final question = _questions[_currentQuestionIndex];

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        if (_isAnswerChecked) return;
        setState(() {
          // Clear choice from any other slot first to support moving between slots
          _slotContents.forEach((key, val) {
            if (val == details.data) {
              _slotContents[key] = null;
            }
          });
          _slotContents[slotId] = details.data;
        });
      },
      builder: (context, candidateData, rejectedData) {
        if (placedIndex != null) {
          final String placedValue = question.choices[placedIndex];
          bool isHovered = false;
          return StatefulBuilder(
            builder: (context, setSubState) {
              return MouseRegion(
                onEnter: (_) => setSubState(() => isHovered = true),
                onExit: (_) => setSubState(() => isHovered = false),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isAnswerChecked) return;
                        setState(() {
                          _slotContents[slotId] = null;
                        });
                      },
                      child: _buildChoiceChip(placedValue, isSlottedStyle: true),
                    ),
                    if (isHovered && !_isAnswerChecked)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _slotContents[slotId] = null;
                            });
                          },
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE55353),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        } else {
          final bool isHovered = candidateData.isNotEmpty;
          return Container(
            height: 38,
            constraints: const BoxConstraints(minWidth: 70),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHovered ? const Color(0xFFFFB020) : const Color(0xFFC0C4CC),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              placeholder,
              style: GoogleFonts.firaCode(
                fontSize: 13,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      },
    );
  }

  // Helper: Choice Chip
  Widget _buildChoiceChip(
    String text, {
    bool isPlaced = false,
    bool isSlottedStyle = false,
    bool isDragging = false,
  }) {
    // Curated themed palette styling
    Color bgColor = Colors.white;
    Color textColor = const Color(0xFF334E68);
    double elevation = isDragging ? 4.0 : 2.0;

    if (isDragging) {
      bgColor = Colors.white.withValues(alpha: 0.85);
      textColor = const Color(0xFF334E68).withValues(alpha: 0.85);
    } else if (isSlottedStyle) {
      bgColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF1E2A38);
      elevation = 0;
    } else if (isPlaced) {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade400;
      elevation = 0;
    } else {
      // Color choices palette dynamically
      if (text.startsWith("print") || text.startsWith("printf")) {
        bgColor = const Color(0xFFD6C8FF);
        textColor = const Color(0xFF6B4EE6);
      } else if (text.startsWith("\"")) {
        bgColor = const Color(0xFFC5E9FF);
        textColor = const Color(0xFF1D83B5);
      } else if (text.startsWith(")") || text.startsWith("(")) {
        bgColor = const Color(0xFFC4F2D6);
        textColor = const Color(0xFF238647);
      } else if (text.startsWith("end=") || text.startsWith("show")) {
        bgColor = const Color(0xFFFFE0A3);
        textColor = const Color(0xFFB5701B);
      }
    }

    return Material(
      elevation: elevation,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      color: bgColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSlottedStyle
              ? Border.all(color: const Color(0xFFCBD5E1), width: 1)
              : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.firaCode(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // Bottom action bar
  Widget _buildBottomActionBar() {
    if (!_isAnswerChecked) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Duo3dButton(
          faceColor: const Color(0xFFFFB020),
          shadowColor: const Color(0xFFD88900),
          height: 52,
          onPressed: _onCheckAnswer,
          child: Text(
            "RUN CODE",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    final Color barColor = _isAnswerCorrect ? const Color(0xFFE3FCEF) : const Color(0xFFFFECEB);
    final Color textColor = _isAnswerCorrect ? const Color(0xFF1E8A44) : const Color(0xFFD32F2F);
    final String resultIcon = _isAnswerCorrect ? "🎉" : "😢";
    final String resultTitle = _isAnswerCorrect ? "Correct!" : "Incorrect";

    return Container(
      width: double.infinity,
      color: barColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(resultIcon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resultTitle,
                  style: GoogleFonts.nunito(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                if (!_isAnswerCorrect)
                  Text(
                    "Keep studying!",
                    style: GoogleFonts.nunito(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: Duo3dButton(
              faceColor: _isAnswerCorrect ? const Color(0xFF2ECC71) : const Color(0xFFE55353),
              shadowColor: _isAnswerCorrect ? const Color(0xFF27AE60) : const Color(0xFFC0392B),
              height: 48,
              onPressed: _onContinueGameplay,
              child: Text(
                "CONTINUE",
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Results View
  Widget _buildResultsView() {
    final bool isVictory = _userScore > _opponentScore;
    final bool isDefeat = _userScore < _opponentScore;

    Color bgGradientStart = const Color(0xFF2ECC71);
    Color bgGradientEnd = const Color(0xFF27AE60);
    String headerText = "Victory!";
    String scoreSubtitle = "You dominated Erica in the duel!";
    String iconString = "👑";

    if (isDefeat) {
      bgGradientStart = const Color(0xFF9E2A2B);
      bgGradientEnd = const Color(0xFF5E1914);
      headerText = "Defeat";
      scoreSubtitle = "Erica was faster this time.";
      iconString = "😢";
    } else if (!isVictory && !isDefeat) {
      bgGradientStart = const Color(0xFFF39C12);
      bgGradientEnd = const Color(0xFFD35400);
      headerText = "Draw!";
      scoreSubtitle = "You both ended with equal scores!";
      iconString = "🤝";
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientStart, bgGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: SvgPicture.asset(
                  'assets/images/codu_background_pattern_mobile_soft.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    const Spacer(),
                    // Match Over visual
                    Text(
                      iconString,
                      style: const TextStyle(fontSize: 72),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headerText,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      scoreSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Results Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scores details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "Your Score",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF9AAEC4),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$_userScore",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF1E2A38),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 2,
                                height: 40,
                                color: const Color(0xFFE2E8F0),
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Erica's Score",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF9AAEC4),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$_opponentScore",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF1E2A38),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Trophies Adjustments
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "🏆",
                                style: TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _trophyDelta >= 0 ? "+$_trophyDelta" : "$_trophyDelta",
                                style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: _trophyDelta >= 0
                                      ? const Color(0xFF2ECC71)
                                      : const Color(0xFFE55353),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Trophies",
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1E2A38),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),

                          // Continue Button
                          Duo3dButton(
                            faceColor: const Color(0xFFFFB020),
                            shadowColor: const Color(0xFFD88900),
                            height: 52,
                            onPressed: () {
                              _updateState(DuelState.lobby);
                              _loadUserData();
                            },
                            child: Text(
                              "CONTINUE",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format Elapsed seconds to 0:00
  String _formatTimer(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }
}
