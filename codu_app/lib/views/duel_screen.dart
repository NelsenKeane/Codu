import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_models.dart';
import '../services/user_data_service.dart';
import '../services/friend_service.dart';
import '../services/audio_service.dart';
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

  // Selected language for the duel
  String _selectedLanguage = "Python";

  // User stats
  String _displayName = "Alex";
  int _trophies = 0;
  int _avatarIndex = 0;
  int _wins = 12;
  int _losses = 8;
  int _streak = 3;

  // Opponent details
  String _opponentName = "Erica";
  int _opponentAvatarIndex = 2; // Female3 (matches user image)
  int _opponentTrophies = 155;

  // Firestore references
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  String? _duelDocId;
  bool _isHost = false;
  int _lastOpponentEmoteTime = 0;
  bool _userFinished = false;
  bool _opponentFinished = false;

  // Matchmaking status strings
  final List<String> _searchStatuses = [
    "Reaching Codu matchmaking servers...",
    "Searching for opponent in range...",
    "Matching trophy level...",
    "Syncing game lobby latency...",
  ];
  String _searchStatusText = "Connecting...";

  // Timers
  Timer? _searchTimer;
  int _searchSeconds = 0;

  Timer? _countdownTimer;
  int _countdownSeconds = 5;

  Timer? _roundTimer;
  int _roundSecondsLeft = 90;

  Timer? _opponentActionTimer;
  int _opponentQuestionsAnswered = 0;

  Timer? _userEmoteTimer;
  Timer? _opponentEmoteTimer;

  // Scores
  int _userScore = 0;
  int _opponentScore = 0;
  int _userScorePrevious = 0;
  int _opponentScorePrevious = 0;

  // Emotes state
  String? _userEmotePath;
  String? _opponentEmotePath;
  bool _showEmotePicker = false;

  // Gameplay quiz
  late List<CodingQuestion> _questions;
  int _currentQuestionIndex = 0;
  bool _isAnswerChecked = false;
  bool _isAnswerCorrect = false;
  final Map<String, int?> _slotContents = {};

  int _trophyDelta = 0;

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _radarController;
  late AnimationController _slideController;
  late AnimationController _confettiController;

  late Animation<Offset> _userCardSlide;
  late Animation<Offset> _opponentCardSlide;

  // Confetti particles for Victory screen
  final List<ConfettiParticle> _confettiParticles = [];

  final List<Map<String, dynamic>> _languagesList = [
    {
      'lang': 'Python',
      'icon': '🐍',
      'color1': const Color(0xFF8F93EA),
      'color2': const Color(0xFF7076E3),
    },
    {
      'lang': 'Javascript',
      'icon': 'JS',
      'color1': const Color(0xFFFFD56B),
      'color2': const Color(0xFFE5A93B),
    },
    {
      'lang': 'C++',
      'icon': 'C+',
      'color1': const Color(0xFF7A9EFF),
      'color2': const Color(0xFF5672E5),
    },
    {
      'lang': 'Java',
      'icon': '☕',
      'color1': const Color(0xFFFF8B8B),
      'color2': const Color(0xFFE55353),
    },
  ];

  final List<Map<String, dynamic>> _avatars = [
    {'svgPath': 'assets/images/Characters/Female1.svg', 'bgColor': const Color(0xFFFFD56B), 'name': 'Female 1'},
    {'svgPath': 'assets/images/Characters/Female2.svg', 'bgColor': const Color(0xFF8F93EA), 'name': 'Female 2'},
    {'svgPath': 'assets/images/Characters/Female3.svg', 'bgColor': const Color(0xFFFF8B8B), 'name': 'Female 3'},
    {'svgPath': 'assets/images/Characters/Male1.svg', 'bgColor': const Color(0xFFFFC5A5), 'name': 'Male 1'},
    {'svgPath': 'assets/images/Characters/Male2.svg', 'bgColor': const Color(0xFF7A9EFF), 'name': 'Male 2'},
    {'svgPath': 'assets/images/Characters/Male3.svg', 'bgColor': const Color(0xFF8CEEAD), 'name': 'Male 3'},
  ];

  final List<Map<String, String>> _emotes = [
    {'name': 'Hi', 'svg': 'assets/images/CoduExpression/codu hi.svg'},
    {'name': 'Thinking', 'svg': 'assets/images/CoduExpression/codu thinking.svg'},
    {'name': 'Angry', 'svg': 'assets/images/CoduExpression/codu angry.svg'},
    {'name': 'Cry', 'svg': 'assets/images/CoduExpression/codu cry.svg'},
    {'name': 'YEY', 'svg': 'assets/images/CoduExpression/codu YEY.svg'},
    {'name': 'Broken', 'svg': 'assets/images/CoduExpression/codu broken.svg'},
    {'name': 'Sad', 'svg': 'assets/images/CoduExpression/codu sad.svg'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Pulse animation for buttons and radar waves
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Radar scan spinning
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Slide-in animations for Match Found screen
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _userCardSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _opponentCardSlide = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Confetti animation for Results screen
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Generate random confetti particles
    final rand = Random();
    final List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.orange, Colors.purple, Colors.pink];
    for (int i = 0; i < 28; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: rand.nextDouble() * 360,
        y: -20.0 - rand.nextDouble() * 100,
        speed: 1.0 + rand.nextDouble() * 1.5,
        size: 8.0 + rand.nextDouble() * 10.0,
        color: colors[rand.nextInt(colors.length)],
        angle: rand.nextDouble() * pi,
      ));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onShowBottomBarChanged?.call(true);
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _countdownTimer?.cancel();
    _roundTimer?.cancel();
    _opponentActionTimer?.cancel();
    _userEmoteTimer?.cancel();
    _opponentEmoteTimer?.cancel();
    _roomSubscription?.cancel();
    if (_isHost && _duelDocId != null) {
      _db.collection('duels').doc(_duelDocId).delete().catchError((e) {});
    }
    _pulseController.dispose();
    _radarController.dispose();
    _slideController.dispose();
    _confettiController.dispose();
    if (_currentState == DuelState.gameplay) {
      AudioService().stopMusic();
    }
    AudioService().stopTimeRunningOut();
    super.dispose();
  }

  void _updateState(DuelState state) {
    if (mounted) {
      setState(() {
        _currentState = state;
      });
      // Hide bottom bar during match transitions (everything except Lobby)
      widget.onShowBottomBarChanged?.call(state == DuelState.lobby);
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = await UserDataService().getDisplayName();
    final trophies = await UserDataService().getTrophies();
    final avatar = await UserDataService().getAvatarIndex();
    final wins = await UserDataService().getWins();
    final losses = await UserDataService().getLosses();
    final streak = await UserDataService().getStreak();

    String email = user?.email ?? "student@codu.com";
    String localUsername = email.split('@')[0];

    String finalDisplayName;
    if (name != null && name.trim().isNotEmpty) {
      finalDisplayName = name;
    } else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      finalDisplayName = user.displayName!;
    } else {
      finalDisplayName = localUsername;
    }

    if (mounted) {
      setState(() {
        _displayName = finalDisplayName;
        _trophies = trophies;
        _avatarIndex = avatar;
        _wins = wins;
        _losses = losses;
        _streak = streak;
      });
    }
  }

  // --- TRANSITIONS & MATCHMAKING FLOW ---

  Future<void> _startSearching() async {
    _updateState(DuelState.searching);
    setState(() {
      _searchSeconds = 0;
      _searchStatusText = _searchStatuses[0];
    });

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to play!")),
      );
      _updateState(DuelState.lobby);
      return;
    }

    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _searchSeconds++;
          _searchStatusText = _searchStatuses[_searchSeconds % _searchStatuses.length];
        });
      }
    });

    try {
      // 1. Query for an existing waiting room for the selected language
      final querySnap = await _db
          .collection('duels')
          .where('status', isEqualTo: 'waiting')
          .where('language', isEqualTo: _selectedLanguage)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        // Room found! Join as guest
        final roomDoc = querySnap.docs.first;
        final roomData = roomDoc.data();
        
        if (roomData['hostUid'] != currentUid) {
          _duelDocId = roomDoc.id;
          _isHost = false;

          await _db.collection('duels').doc(_duelDocId).update({
            'status': 'starting',
            'guestUid': currentUid,
            'guestName': _displayName,
            'guestAvatarIndex': _avatarIndex,
            'guestTrophies': _trophies,
            'guestScore': 0,
            'guestQuestionIndex': 0,
            'guestFinished': false,
            'guestForfeited': false,
          });

          _subscribeToRoom();
          return;
        }
      }

      // 2. If no room found or own room was retrieved, create a new room as host
      final int seed = Random().nextInt(100) + 1;
      _duelDocId = currentUid;
      _isHost = true;

      await _db.collection('duels').doc(_duelDocId).set({
        'status': 'waiting',
        'language': _selectedLanguage,
        'questionSeed': seed,
        'createdAt': FieldValue.serverTimestamp(),
        'hostUid': currentUid,
        'hostName': _displayName,
        'hostAvatarIndex': _avatarIndex,
        'hostTrophies': _trophies,
        'hostScore': 0,
        'hostQuestionIndex': 0,
        'hostFinished': false,
        'hostForfeited': false,
        'guestUid': null,
        'guestName': null,
        'guestAvatarIndex': 0,
        'guestTrophies': 0,
        'guestScore': 0,
        'guestQuestionIndex': 0,
        'guestFinished': false,
        'guestForfeited': false,
      });

      _subscribeToRoom();

    } catch (e) {
      debugPrint("Error starting search: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
      _cancelSearching();
    }
  }

  void _subscribeToRoom() {
    _roomSubscription?.cancel();
    if (_duelDocId == null) return;

    _roomSubscription = _db.collection('duels').doc(_duelDocId).snapshots().listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'];

      if (status == 'starting' && _currentState == DuelState.searching) {
        _searchTimer?.cancel();
        _triggerMatchFound(data);
      }

      if (status == 'active' && !_isHost && _currentState == DuelState.matchFound) {
        _countdownTimer?.cancel();
        _startDuelGameplayMultiplayer(data);
      }

      if (_currentState == DuelState.gameplay) {
        final emoteMap = _isHost ? data['guestEmote'] : data['hostEmote'];
        final int emoteTime = emoteMap?['time'] ?? 0;
        final String? emotePath = emoteMap?['svg'];

        setState(() {
          if (_isHost) {
            _opponentScorePrevious = _opponentScore;
            _opponentScore = data['guestScore'] ?? 0;
            _opponentQuestionsAnswered = data['guestQuestionIndex'] ?? 0;
            _opponentFinished = data['guestFinished'] ?? false;
          } else {
            _opponentScorePrevious = _opponentScore;
            _opponentScore = data['hostScore'] ?? 0;
            _opponentQuestionsAnswered = data['hostQuestionIndex'] ?? 0;
            _opponentFinished = data['hostFinished'] ?? false;
          }

          if (emotePath != null && emoteTime > _lastOpponentEmoteTime) {
            _lastOpponentEmoteTime = emoteTime;
            _triggerOpponentEmote(emotePath);
          }
        });

        _checkDuelCompletionMultiplayer(data);
      }
    }, onError: (e) {
      debugPrint("Error in room subscription: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subscription error: $e")),
        );
      }
      _cancelSearching();
    });
  }

  Future<void> _cancelSearching() async {
    _searchTimer?.cancel();
    _roomSubscription?.cancel();
    if (_isHost && _duelDocId != null) {
      try {
        await _db.collection('duels').doc(_duelDocId).delete();
      } catch (e) {
        debugPrint("Error deleting room: $e");
      }
    }
    _duelDocId = null;
    _updateState(DuelState.lobby);
  }

  void _triggerMatchFound(Map<String, dynamic> data) {
    _updateState(DuelState.matchFound);
    setState(() {
      _countdownSeconds = 5;

      if (_isHost) {
        _opponentName = data['guestName'] ?? "Guest";
        _opponentAvatarIndex = data['guestAvatarIndex'] ?? 0;
        _opponentTrophies = data['guestTrophies'] ?? 0;
      } else {
        _opponentName = data['hostName'] ?? "Host";
        _opponentAvatarIndex = data['hostAvatarIndex'] ?? 0;
        _opponentTrophies = data['hostTrophies'] ?? 0;
      }
    });

    _slideController.forward(from: 0.0);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) {
          setState(() {
            _countdownSeconds--;
          });
        }
      }
      if (_countdownSeconds == 0) {
        timer.cancel();
        if (_isHost) {
          _startDuelGameplayMultiplayer(data);
        }
      }
    });
  }

  Future<void> _cancelMatchFound() async {
    _countdownTimer?.cancel();
    _roomSubscription?.cancel();
    if (_duelDocId != null) {
      try {
        if (_isHost) {
          await _db.collection('duels').doc(_duelDocId).delete();
        } else {
          await _db.collection('duels').doc(_duelDocId).update({
            'status': 'waiting',
            'guestUid': null,
            'guestName': null,
            'guestAvatarIndex': 0,
            'guestTrophies': 0,
          });
        }
      } catch (e) {
        debugPrint("Error cancelling match found: $e");
      }
    }
    _duelDocId = null;
    _updateState(DuelState.lobby);
  }

  void _startDuelGameplayMultiplayer(Map<String, dynamic> data) {
    _updateState(DuelState.gameplay);
    AudioService().playMusic('Audio/Game Music.mp3');

    final int seed = data['questionSeed'] ?? 1;

    setState(() {
      _roundSecondsLeft = 90;
      _currentQuestionIndex = 0;
      _userScore = 0;
      _opponentScore = 0;
      _userScorePrevious = 0;
      _opponentScorePrevious = 0;
      _opponentQuestionsAnswered = 0;
      _opponentFinished = false;
      _userFinished = false;
      _userEmotePath = null;
      _opponentEmotePath = null;
      _showEmotePicker = false;
      _lastOpponentEmoteTime = 0;

      _questions = QuestionBank.getQuestionsForLevel(seed, _selectedLanguage).sublist(0, 5);
    });

    _clearSlots();

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_roundSecondsLeft > 1) {
        if (mounted) {
          setState(() {
            _roundSecondsLeft--;
          });
        }
        if (_roundSecondsLeft == 5) {
          AudioService().playTimeRunningOut();
        }
      } else {
        timer.cancel();
        _endDuelMultiplayer(timeOut: true);
      }
    });

    if (_isHost && _duelDocId != null) {
      _db.collection('duels').doc(_duelDocId).update({'status': 'active'}).catchError((e) {});
    }

    _triggerUserEmote("assets/images/CoduExpression/codu hi.svg");
  }

  // --- GAME EVALUATION ---

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

    bool allFilled = true;
    _slotContents.forEach((key, value) {
      if (value == null) allFilled = false;
    });

    if (!allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fill all code blanks first!"),
          backgroundColor: Color(0xFFFFB020),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
        _userScorePrevious = _userScore;
        _userScore += 20;

        _triggerUserEmote("assets/images/CoduExpression/codu YEY.svg");
      } else {
        _triggerUserEmote("assets/images/CoduExpression/codu sad.svg");
      }
    });

    if (correct) {
      AudioService().playSfx('Audio/Correct.mp3');
    } else {
      AudioService().playSfx('Audio/Wrong.mp3');
    }

    _syncUserProgressToFirestore();
  }

  void _onContinueGameplay() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _clearSlots();
      });
      _syncUserProgressToFirestore();
    } else {
      setState(() {
        _userFinished = true;
      });
      _syncUserFinishedToFirestore();
    }
  }

  void _checkDuelCompletionMultiplayer(Map<String, dynamic> data) {
    if (_currentState != DuelState.gameplay) return;

    final bool hostFinished = data['hostFinished'] == true || data['hostForfeited'] == true;
    final bool guestFinished = data['guestFinished'] == true || data['guestForfeited'] == true;

    final bool opponentForfeited = _isHost ? (data['guestForfeited'] == true) : (data['hostForfeited'] == true);

    if (opponentForfeited) {
      setState(() {
        _opponentScore = 0;
        _userScore = 100; // ensure victory
      });
      _endDuelMultiplayer();
    } else if (hostFinished && guestFinished) {
      _endDuelMultiplayer();
    }
  }

  Future<void> _endDuelMultiplayer({bool timeOut = false}) async {
    _roundTimer?.cancel();
    _roomSubscription?.cancel();
    AudioService().stopMusic();
    AudioService().stopTimeRunningOut();

    int delta = 0;
    int newWins = _wins;
    int newLosses = _losses;
    int newStreak = _streak;

    if (_userScore > _opponentScore) {
      delta = 30;
      _confettiController.repeat();
      AudioService().playSfx('Audio/Completed.mp3');
      newWins = _wins + 1;
      await UserDataService().saveWins(newWins);
      
      int currentStreak = await UserDataService().getStreak();
      newStreak = currentStreak + 1;
      await UserDataService().saveStreak(newStreak);
    } else if (_userScore < _opponentScore) {
      delta = -15;
      _confettiController.stop();
      AudioService().playSfx('Audio/CompletedLose.mp3');
      newLosses = _losses + 1;
      await UserDataService().saveLosses(newLosses);
      
      int currentStreak = await UserDataService().getStreak();
      newStreak = currentStreak + 1;
      await UserDataService().saveStreak(newStreak);
    } else {
      delta = 5;
      _confettiController.repeat();
      AudioService().playSfx('Audio/Completed.mp3');
      
      int currentStreak = await UserDataService().getStreak();
      newStreak = currentStreak + 1;
      await UserDataService().saveStreak(newStreak);
    }

    int newTrophies = max(0, _trophies + delta);
    await UserDataService().saveTrophies(newTrophies);

    // Sync all updated stats to Firestore
    await FriendService().syncUserToFirestore().catchError((e) {
      debugPrint("Failed to sync stats to Firestore on end match: $e");
    });

    setState(() {
      _trophyDelta = delta;
      _wins = newWins;
      _losses = newLosses;
      _streak = newStreak;
      _trophies = newTrophies;
    });

    _updateState(DuelState.results);

    // Clean up room doc from Firestore
    if (_duelDocId != null) {
      try {
        await _db.collection('duels').doc(_duelDocId).delete();
      } catch (e) {
        debugPrint("Error deleting room doc on end: $e");
      }
    }
    _duelDocId = null;
  }

  Future<void> _syncUserProgressToFirestore() async {
    if (_duelDocId == null) return;
    try {
      if (_isHost) {
        await _db.collection('duels').doc(_duelDocId).update({
          'hostScore': _userScore,
          'hostQuestionIndex': _currentQuestionIndex + (_isAnswerChecked && _isAnswerCorrect ? 1 : 0),
        });
      } else {
        await _db.collection('duels').doc(_duelDocId).update({
          'guestScore': _userScore,
          'guestQuestionIndex': _currentQuestionIndex + (_isAnswerChecked && _isAnswerCorrect ? 1 : 0),
        });
      }
    } catch (e) {
      debugPrint("Error syncing user progress: $e");
    }
  }

  Future<void> _syncUserFinishedToFirestore() async {
    if (_duelDocId == null) return;
    try {
      if (_isHost) {
        await _db.collection('duels').doc(_duelDocId).update({
          'hostFinished': true,
        });
      } else {
        await _db.collection('duels').doc(_duelDocId).update({
          'guestFinished': true,
        });
      }
    } catch (e) {
      debugPrint("Error syncing user finished: $e");
    }
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
    _roundTimer?.cancel();
    _roomSubscription?.cancel();
    AudioService().stopMusic();
    AudioService().stopTimeRunningOut();
    AudioService().playSfx('Audio/CompletedLose.mp3');

    if (_duelDocId != null) {
      try {
        if (_isHost) {
          await _db.collection('duels').doc(_duelDocId).update({
            'hostForfeited': true,
            'hostFinished': true,
          });
        } else {
          await _db.collection('duels').doc(_duelDocId).update({
            'guestForfeited': true,
            'guestFinished': true,
          });
        }
      } catch (e) {
        debugPrint("Error forfeiting match: $e");
      }
    }

    int newLosses = _losses + 1;
    await UserDataService().saveLosses(newLosses);
    
    int currentStreak = await UserDataService().getStreak();
    int newStreak = currentStreak + 1;
    await UserDataService().saveStreak(newStreak);

    int newTrophies = max(0, _trophies - 15);
    await UserDataService().saveTrophies(newTrophies);

    // Sync all updated stats to Firestore
    await FriendService().syncUserToFirestore().catchError((e) {
      debugPrint("Failed to sync stats to Firestore on forfeit: $e");
    });

    setState(() {
      _trophyDelta = -15;
      _userScore = 0;
      _opponentScore = 100;
      _losses = newLosses;
      _streak = newStreak;
      _trophies = newTrophies;
    });
    _updateState(DuelState.results);
  }

  Future<void> _triggerUserEmote(String assetPath) async {
    _userEmoteTimer?.cancel();
    setState(() {
      _userEmotePath = assetPath;
    });

    if (_duelDocId != null) {
      try {
        final emoteData = {
          'svg': assetPath,
          'time': DateTime.now().millisecondsSinceEpoch,
        };
        if (_isHost) {
          await _db.collection('duels').doc(_duelDocId).update({
            'hostEmote': emoteData,
          });
        } else {
          await _db.collection('duels').doc(_duelDocId).update({
            'guestEmote': emoteData,
          });
        }
      } catch (e) {
        debugPrint("Error sending emote: $e");
      }
    }

    _userEmoteTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _userEmotePath = null;
        });
      }
    });
  }

  void _triggerOpponentEmote(String assetPath) {
    _opponentEmoteTimer?.cancel();
    setState(() {
      _opponentEmotePath = assetPath;
    });
    _opponentEmoteTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _opponentEmotePath = null;
        });
      }
    });
  }

  // --- UI LAYOUT BUILDERS ---

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

  // 1. LOBBY VIEW
  Widget _buildLobbyView() {
    return Container(
      color: const Color(0xFFF0F2F6),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: SvgPicture.asset(
                'assets/images/codu_background_pattern_mobile_soft.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    // Visual Controller Header
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F80ED).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Coding Duel",
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF1E2A38),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Solve faster than your opponent to win trophies!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF9AAEC4),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Trophies & Stats Box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("🏆", style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "YOUR TROPHIES",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF9AAEC4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    "$_trophies",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF1E2A38),
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Divider(color: Color(0xFFE2E8F0)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem("WINS", "$_wins", Colors.green),
                              _buildStatItem("LOSSES", "$_losses", Colors.redAccent),
                              _buildStatItem("STREAK", "🔥 $_streak", Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Language Selection Carousel Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          "Choose Subject",
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF1E2A38),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Language selection carousel
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _languagesList.length,
                        itemBuilder: (context, index) {
                          final item = _languagesList[index];
                          final bool isSelected = _selectedLanguage == item['lang'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLanguage = item['lang'];
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 110,
                              margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [item['color1'], item['color2']],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: item['color2'].withValues(alpha: isSelected ? 0.5 : 0.25),
                                    blurRadius: isSelected ? 8 : 4,
                                    offset: Offset(0, isSelected ? 4 : 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -10,
                                    bottom: -10,
                                    child: Opacity(
                                      opacity: 0.15,
                                      child: Text(
                                        item['icon'],
                                        style: const TextStyle(fontSize: 54),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['icon'],
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        Text(
                                          item['lang'],
                                          style: GoogleFonts.nunito(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Find Match Pulsing Button
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1.02).animate(_pulseController),
                      child: SizedBox(
                        width: 220,
                        child: Duo3dButton(
                          faceColor: const Color(0xFFFFB020),
                          shadowColor: const Color(0xFFD88900),
                          height: 54,
                          borderRadius: 27,
                          onPressed: _startSearching,
                          child: Text(
                            "FIND MATCH",
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper stats item
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: const Color(0xFF9AAEC4),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // 2. SEARCHING VIEW
  Widget _buildSearchingView() {
    return Container(
      color: const Color(0xFFF0F2F6),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
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
                    // Spinning Radar with Waves
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing outer ring
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.6).animate(_pulseController),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.5, end: 0.0).animate(_pulseController),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF56CCF2), width: 3),
                              ),
                            ),
                          ),
                        ),
                        // Secondary outer wave
                        ScaleTransition(
                          scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                            CurvedAnimation(parent: _pulseController, curve: const Interval(0.2, 1.0)),
                          ),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0.3, end: 0.0).animate(
                              CurvedAnimation(parent: _pulseController, curve: const Interval(0.2, 1.0)),
                            ),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF56CCF2), width: 2),
                              ),
                            ),
                          ),
                        ),
                        // Spinning Radar sweep
                        RotationTransition(
                          turns: _radarController,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  const Color(0xFF56CCF2).withValues(alpha: 0.05),
                                  const Color(0xFF56CCF2),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Solid inner status circle
                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(
                            Icons.youtube_searched_for_rounded,
                            color: Color(0xFF2F80ED),
                            size: 38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Status and language info
                    Text(
                      _searchStatusText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF1E2A38),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Subject: $_selectedLanguage",
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF2F80ED),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatTimer(_searchSeconds),
                      style: GoogleFonts.firaCode(
                        color: const Color(0xFF9AAEC4),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Cancel
                    SizedBox(
                      width: 160,
                      child: Duo3dButton(
                        faceColor: const Color(0xFFE55353),
                        shadowColor: const Color(0xFFB83C3C),
                        height: 46,
                        borderRadius: 23,
                        onPressed: _cancelSearching,
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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

  // 3. MATCH FOUND VIEW (Countdown and Slide entry)
  Widget _buildMatchFoundView() {
    final Map<String, dynamic> activeAvatar = _avatars[_avatarIndex];
    final Map<String, dynamic> opponentAvatar = _avatars[_opponentAvatarIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF4AC4FF),
      body: Stack(
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: _cancelMatchFound,
                    ),
                  ),
                ),
                const Spacer(flex: 1),

                Text(
                  "Match Found!",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(flex: 2),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      // User Card (Slide Transition)
                      SlideTransition(
                        position: _userCardSlide,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
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
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayName,
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF1E2A38),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3E8FA),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Text("🏆", style: TextStyle(fontSize: 12)),
                                            const SizedBox(width: 4),
                                            Text(
                                              "$_trophies",
                                              style: GoogleFonts.nunito(
                                                color: const Color(0xFF9B51E0),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
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
                            Positioned(
                              top: -8,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9B51E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "You",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Text(
                          "VS",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      // Opponent Card (Slide Transition)
                      SlideTransition(
                        position: _opponentCardSlide,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
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
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _opponentName,
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF1E2A38),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FA),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text("🏆", style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text(
                                          "$_opponentTrophies",
                                          style: GoogleFonts.nunito(
                                            color: const Color(0xFF9B51E0),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
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
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Countdown info
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE55353),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _countdownSeconds == 0
                          ? "Starting match..."
                          : "Match starts in $_countdownSeconds seconds",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Cancel match
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Duo3dButton(
                    faceColor: const Color(0xFFFFB020),
                    shadowColor: const Color(0xFFD88900),
                    height: 50,
                    borderRadius: 25,
                    onPressed: _cancelMatchFound,
                    child: Text(
                      "Cancel match",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 16,
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

  // 4. GAMEPLAY VIEW
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
                  // --- HEADER WITH AVATARS, SCORES & EMOTES ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                              onPressed: () async {
                                final shouldPop = await _confirmForfeit();
                                if (shouldPop && mounted) {
                                  _forfeitMatch();
                                }
                              },
                            ),
                            const Expanded(child: SizedBox()),
                            Text(
                              "$_selectedLanguage Duel",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // User (Alex) Avatar + Floating Emote Bubble
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  children: [
                                    // Shake/Scale animation on User score update
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 300),
                                      tween: Tween<double>(begin: 1.0, end: _userScore != _userScorePrevious ? 1.25 : 1.0),
                                      builder: (context, val, child) {
                                        return Transform.scale(
                                          scale: val,
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: activeAvatar['bgColor'],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2.5),
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
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _displayName,
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                // Score Badge
                                Positioned(
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB020),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "$_userScore",
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                // Floating Emote bubble above User Avatar
                                if (_userEmotePath != null)
                                  Positioned(
                                    top: -45,
                                    left: -20,
                                    child: _buildEmoteBubble(_userEmotePath!),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Circular Active Countdown Round Timer
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: _roundSecondsLeft / 90.0,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _roundSecondsLeft > 20 ? Colors.white : Colors.redAccent,
                                    ),
                                  ),
                                  Text(
                                    "$_roundSecondsLeft",
                                    style: GoogleFonts.firaCode(
                                      color: _roundSecondsLeft > 20 ? Colors.white : Colors.redAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Opponent (Erica) Avatar + Floating Emote Bubble
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  children: [
                                    // Shake/Scale animation on Opponent score update
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 300),
                                      tween: Tween<double>(begin: 1.0, end: _opponentScore != _opponentScorePrevious ? 1.25 : 1.0),
                                      builder: (context, val, child) {
                                        return Transform.scale(
                                          scale: val,
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: opponentAvatar['bgColor'],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2.5),
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
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _opponentName,
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                // Score Badge
                                Positioned(
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2ECC71),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "$_opponentScore",
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                // Floating Emote bubble above Erica's Avatar
                                if (_opponentEmotePath != null)
                                  Positioned(
                                    top: -45,
                                    right: -20,
                                    child: _buildEmoteBubble(_opponentEmotePath!, isLeftTail: false),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress Bar
                        Container(
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: constraints.maxWidth * progress,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB020),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- WORKSPACE PANEL ---
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F2F6),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
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
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      // Code Question Card
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.03),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              question.instruction,
                                              style: GoogleFonts.nunito(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF2C3E50),
                                                height: 1.25,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // Indented Code Panel
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(14.0),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F7FA),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                              ),
                                              child: _buildCodeLines(question),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Choices palette
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 10,
                                        alignment: WrapAlignment.center,
                                        children: List.generate(question.choices.length, (index) {
                                          final choice = question.choices[index];
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

                              // Bottom Actions (run/continue)
                              _buildBottomActionBar(),
                            ],
                          ),

                          // Floating Emote Button + Picker
                          Positioned(
                            bottom: _isAnswerChecked ? 96 : 84,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Emote Quick Picker
                                if (_showEmotePicker)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3)),
                                      ],
                                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                                    ),
                                    child: Row(
                                      children: _emotes.map((e) {
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showEmotePicker = false;
                                            });
                                            _triggerUserEmote(e['svg']!);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                            child: SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: SvgPicture.asset(
                                                e['svg']!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                // Emote Palette toggler button
                                FloatingActionButton(
                                  mini: true,
                                  backgroundColor: const Color(0xFF9B51E0),
                                  onPressed: () {
                                    setState(() {
                                      _showEmotePicker = !_showEmotePicker;
                                    });
                                  },
                                  child: const Icon(Icons.insert_emoticon_rounded, color: Colors.white),
                                ),
                              ],
                            ),
                          ),

                          // Opponent finished loading overlay
                          if (_userFinished && !_opponentFinished)
                            Container(
                              color: Colors.black.withValues(alpha: 0.65),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  margin: const EdgeInsets.symmetric(horizontal: 32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(
                                        color: Color(0xFFFFB020),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "Waiting for opponent...",
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF1E2A38),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$_opponentName is answering question ${_opponentQuestionsAnswered + 1}/5",
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

  // Floating Emote bubble above avatar builder
  Widget _buildEmoteBubble(String emoteAsset, {bool isLeftTail = true}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(6),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(emoteAsset, fit: BoxFit.contain),
            // Speech tail
            Positioned(
              bottom: -10,
              left: isLeftTail ? 12 : null,
              right: isLeftTail ? null : 12,
              child: CustomPaint(
                size: const Size(12, 10),
                painter: TrianglePainter(isLeft: isLeftTail),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Code line builder
  Widget _buildCodeLines(CodingQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: question.codeLines.map((line) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
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
                  final double indentWidth = (spacesCount / 4) * 16.0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: indentWidth),
                      Text(
                        text.trimLeft(),
                        style: GoogleFonts.firaCode(
                          fontSize: 13,
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
                    fontSize: 13,
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

  // Drag and Drop Slot
  Widget _buildSlotTarget(String slotId, String placeholder) {
    final int? placedIndex = _slotContents[slotId];
    final question = _questions[_currentQuestionIndex];

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        if (_isAnswerChecked) return;
        setState(() {
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
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _slotContents[slotId] = null;
                            });
                          },
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE55353),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 10,
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
            height: 34,
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovered ? const Color(0xFFFFB020) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              placeholder,
              style: GoogleFonts.firaCode(
                fontSize: 12,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      },
    );
  }

  // Choices styling
  Widget _buildChoiceChip(
    String text, {
    bool isPlaced = false,
    bool isSlottedStyle = false,
    bool isDragging = false,
  }) {
    Color bgColor = Colors.white;
    Color textColor = const Color(0xFF334E68);
    double elevation = isDragging ? 3.0 : 1.0;

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
      if (text.startsWith("print") || text.startsWith("printf")) {
        bgColor = const Color(0xFFD6C8FF);
        textColor = const Color(0xFF6B4EE6);
      } else if (text.startsWith("\"") || text.startsWith("'")) {
        bgColor = const Color(0xFFC5E9FF);
        textColor = const Color(0xFF1D83B5);
      } else if (text.startsWith(")") || text.startsWith("(")) {
        bgColor = const Color(0xFFC4F2D6);
        textColor = const Color(0xFF238647);
      } else if (text.startsWith("end=") || text.startsWith("show") || text.contains("=")) {
        bgColor = const Color(0xFFFFE0A3);
        textColor = const Color(0xFFB5701B);
      }
    }

    return Material(
      elevation: elevation,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(10),
      color: bgColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: isSlottedStyle ? Border.all(color: const Color(0xFFCBD5E1), width: 1) : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.firaCode(
            fontSize: 13,
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
          height: 48,
          onPressed: _onCheckAnswer,
          child: Text(
            "RUN CODE",
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(resultIcon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
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
                    fontSize: 16,
                  ),
                ),
                if (!_isAnswerCorrect)
                  Text(
                    "Try again in the next slot!",
                    style: GoogleFonts.nunito(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Duo3dButton(
              faceColor: _isAnswerCorrect ? const Color(0xFF2ECC71) : const Color(0xFFE55353),
              shadowColor: _isAnswerCorrect ? const Color(0xFF27AE60) : const Color(0xFFC0392B),
              height: 44,
              onPressed: _onContinueGameplay,
              child: Text(
                "CONTINUE",
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. RESULTS VIEW (Animated count-up and Confetti)
  Widget _buildResultsView() {
    final bool isVictory = _userScore > _opponentScore;
    final bool isDefeat = _userScore < _opponentScore;

    Color bgGradientStart = const Color(0xFF2ECC71);
    Color bgGradientEnd = const Color(0xFF27AE60);
    String headerText = "Victory!";
    String scoreSubtitle = "You dominated $_opponentName in the duel!";
    String iconString = "👑";

    if (isDefeat) {
      bgGradientStart = const Color(0xFF9E2A2B);
      bgGradientEnd = const Color(0xFF5E1914);
      headerText = "Defeat";
      scoreSubtitle = "$_opponentName was faster this time.";
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
            // Confetti Overlay (for Victory only)
            if (isVictory)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ConfettiPainter(
                        particles: _confettiParticles,
                        animationValue: _confettiController.value,
                      ),
                    );
                  },
                ),
              ),

            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
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
                    Text(
                      iconString,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      headerText,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      scoreSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Results Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "Your Score",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF9AAEC4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$_userScore",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF1E2A38),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1.5,
                                height: 36,
                                color: const Color(0xFFE2E8F0),
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Erica's Score",
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFF9AAEC4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$_opponentScore",
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
                          const SizedBox(height: 28),

                          // Trophies Adjustments with Count-Up/Down Animation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("🏆", style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 8),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(seconds: 2),
                                tween: Tween<double>(begin: _trophies.toDouble(), end: (_trophies + _trophyDelta).toDouble()),
                                builder: (context, val, child) {
                                  return Text(
                                    "${val.toInt()}",
                                    style: GoogleFonts.nunito(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E2A38),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _trophyDelta >= 0 ? "(+$_trophyDelta)" : "($_trophyDelta)",
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: _trophyDelta >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFE55353),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          Duo3dButton(
                            faceColor: const Color(0xFFFFB020),
                            shadowColor: const Color(0xFFD88900),
                            height: 48,
                            onPressed: () {
                              _confettiController.stop();
                              _updateState(DuelState.lobby);
                              _loadUserData();
                              AudioService().playMusic('Audio/Menu Music.mp3');
                            },
                            child: Text(
                              "CONTINUE",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
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

  // Format Elapsed seconds
  String _formatTimer(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }
}

// Confetti Particle model
class ConfettiParticle {
  double x;
  double y;
  double speed;
  double size;
  Color color;
  double angle;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.angle,
  });
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animationValue;

  ConfettiPainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      double currentY = p.y + (size.height * animationValue * p.speed) % size.height;
      double currentX = (p.x + sin(animationValue * 6 + p.angle) * 15) % size.width;

      paint.color = p.color;
      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(animationValue * p.angle * 2.5);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

// Triangle painter for Emote bubble tail pointing downwards
class TrianglePainter extends CustomPainter {
  final bool isLeft;
  TrianglePainter({this.isLeft = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) => false;
}
