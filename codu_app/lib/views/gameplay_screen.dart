import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_models.dart';
import '../services/user_data_service.dart';
import '../services/audio_service.dart';
import '../widgets/duo_3d_button.dart';

class GameplayScreen extends StatefulWidget {
  final int levelNumber;
  final String subject;

  const GameplayScreen({
    super.key,
    required this.levelNumber,
    required this.subject,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> with SingleTickerProviderStateMixin {
  late List<CodingQuestion> _questions;
  int _currentQuestionIndex = 0;
  int _hearts = 4;
  int _mistakesCount = 0;
  late DateTime _startTime;

  // Track the content dropped or tapped into each slot ID
  final Map<String, int?> _slotContents = {};

  // Evaluation states
  bool _hasChecked = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _questions = QuestionBank.getQuestionsForLevel(widget.levelNumber, widget.subject);
    _clearSlots();
    _startTime = DateTime.now();
    AudioService().playMusic('Audio/Game Music.mp3');
  }

  @override
  void dispose() {
    AudioService().stopMusic();
    super.dispose();
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
    _hasChecked = false;
  }

  void _handleChoiceTap(int choiceIndex) {
    if (_hasChecked) return;

    final question = _questions[_currentQuestionIndex];

    // Check if it's already placed
    String? alreadyPlacedSlot;
    _slotContents.forEach((key, value) {
      if (value == choiceIndex) {
        alreadyPlacedSlot = key;
      }
    });

    if (alreadyPlacedSlot != null) {
      // Remove it
      setState(() {
        _slotContents[alreadyPlacedSlot!] = null;
      });
    } else {
      // Find the first empty slot
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

  void _onRunCode() {
    if (_hasChecked) return;

    final question = _questions[_currentQuestionIndex];

    // Verify all slots are filled
    bool allFilled = true;
    _slotContents.forEach((key, value) {
      if (value == null) allFilled = false;
    });

    if (!allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Drag or tap choices to fill all the blanks first!"),
          backgroundColor: Color(0xFFFFB020),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Evaluate answers
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
      _hasChecked = true;
      _isCorrect = correct;
      if (!correct) {
        _hearts--;
        _mistakesCount++;
      }
    });

    if (correct) {
      AudioService().playSfx('Audio/Correct.mp3');
    } else {
      AudioService().playSfx('Audio/Wrong.mp3');
    }
  }

  void _onContinue() {
    if (_hearts <= 0) {
      _showGameOverDialog();
      return;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _clearSlots();
      });
    } else {
      _completeLevel();
    }
  }

  Future<void> _completeLevel() async {
    AudioService().stopMusic();
    AudioService().playSfx('Audio/Completed.mp3');
    // Show victory loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFB020),
        ),
      ),
    );

    int earnedStars = 3;
    if (_mistakesCount == 0) {
      earnedStars = 3;
    } else if (_mistakesCount == 1) {
      earnedStars = 2;
    } else {
      earnedStars = 1;
    }

    // Call service to complete progress, streak, trophies, and Firestore sync
    await UserDataService().completeLevel(widget.subject, widget.levelNumber, earnedStars);

    if (mounted) {
      Navigator.of(context).pop(); // Dismiss loader
      _showVictoryScreen(earnedStars);
    }
  }

  void _showVictoryScreen(int earnedStars) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF4AC4FF),
          body: Stack(
            children: [
              // Premium Background Pattern
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
                      // Header Row with Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 26),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const Spacer(),
                      // Header title
                      Text(
                        "You've completed\nthe level!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Main White Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 3 Stars rating row
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, 8),
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 72,
                                      color: earnedStars >= 1 ? const Color(0xFFFFD600) : const Color(0xFFE0E4EC),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Transform.translate(
                                  offset: const Offset(0, -12),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 104,
                                    color: earnedStars >= 2 ? const Color(0xFFFFD600) : const Color(0xFFE0E4EC),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Transform.translate(
                                  offset: const Offset(0, 8),
                                  child: Transform.rotate(
                                    angle: 0.2,
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 72,
                                      color: earnedStars >= 3 ? const Color(0xFFFFD600) : const Color(0xFFE0E4EC),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            // Feedback title
                            Text(
                              earnedStars == 3
                                  ? "Excellent!"
                                  : (earnedStars == 2 ? "Good Job!" : "Keep Practicing!"),
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1E2A38),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Completion time
                            Builder(
                              builder: (context) {
                                final duration = DateTime.now().difference(_startTime);
                                final minutes = duration.inMinutes;
                                final seconds = duration.inSeconds % 60;
                                return Text(
                                  "Completed in $minutes minutes $seconds seconds",
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF9AAEC4),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            // Rewards Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Streak reward
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("🔥", style: TextStyle(fontSize: 26)),
                                    const SizedBox(width: 6),
                                    Text(
                                      "+1",
                                      style: GoogleFonts.nunito(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFE55353),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 48),
                                // Stars reward
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 30),
                                    const SizedBox(width: 6),
                                    Text(
                                      "+$earnedStars",
                                      style: GoogleFonts.nunito(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFFFB020),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            // Next Level 3D Button
                            Duo3dButton(
                              faceColor: const Color(0xFFFF9E1B),
                              shadowColor: const Color(0xFFD47C07),
                              height: 52,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                "Next Level",
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
      ),
    );
  }

  void _showGameOverDialog() {
    AudioService().stopMusic();
    AudioService().playSfx('Audio/CompletedLose.mp3');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: SvgPicture.asset(
            'assets/images/CoduExpression/codu cry.svg',
            width: 100,
            height: 100,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "No Hearts Left!",
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE55353),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Keep practicing and try again! Your coding journey doesn't end here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: const Color(0xFF5A6B7C),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              Navigator.of(context).pop(); // Quit gameplay
            },
            child: Text(
              "Quit",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB020),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              setState(() {
                _hearts = 4;
                _mistakesCount = 0;
                _startTime = DateTime.now();
                _currentQuestionIndex = 0;
                _clearSlots();
              });
              AudioService().playMusic('Audio/Game Music.mp3');
            },
            child: Text(
              "Try Again",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Quit Lesson?",
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
        content: Text(
          "Are you sure you want to quit? You will lose all progress for this level.",
          style: GoogleFonts.nunito(color: const Color(0xFF5A6B7C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Keep Playing",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: const Color(0xFF1D83B5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Quit",
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex) / _questions.length;
    final topicTitle = QuestionBank.getTopicTitle(widget.levelNumber, widget.subject);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F6),
        body: Stack(
          children: [
            // Soft Background Pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: SvgPicture.asset(
                  'assets/images/codu_background_pattern_mobile_soft.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // --- TOP BAR HEADER ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5A6B7C)),
                          onPressed: () async {
                            final shouldPop = await _showExitConfirmation();
                            if (shouldPop && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        // Mascot Robot
                        SvgPicture.asset(
                          _hasChecked
                              ? (_isCorrect
                                  ? 'assets/images/CoduExpression/codu YEY.svg'
                                  : 'assets/images/CoduExpression/codu sad.svg')
                              : 'assets/images/CoduExpression/codu hi.svg',
                          width: 44,
                          height: 44,
                        ),
                        const SizedBox(width: 10),
                        // Progress Bar & Level Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Progress bar container
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE0E4EC), width: 1.5),
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
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Level ${widget.levelNumber} - $topicTitle",
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF5A6B7C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Hearts counter
                        Row(
                          children: [
                            const Text(
                              "❤️",
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$_hearts",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFE55353),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- MAIN EXERCISE PANEL ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
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
                                  color: Colors.black.withValues(alpha: 0.05),
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2C3E50),
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

                          const SizedBox(height: 32),

                          // Palette Choices
                          Wrap(
                            spacing: 10,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: List.generate(question.choices.length, (index) {
                              final choice = question.choices[index];
                              
                              // Check if this choice index has been placed in a slot
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

                  // --- BOTTOM EVALUATION BAR ---
                  _buildBottomActionBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to draw code lines with indentation and slot targets
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
                // Indentation support: check leading 4-space blocks
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

  // Dashed border or filled slot target
  Widget _buildSlotTarget(String slotId, String placeholder) {
    final int? placedIndex = _slotContents[slotId];
    final question = _questions[_currentQuestionIndex];

    return DragTarget<int>(
      builder: (context, candidateData, rejectedData) {
        if (placedIndex != null) {
          final String placedValue = question.choices[placedIndex];
          // Render slotted chip
          return GestureDetector(
            onTap: () {
              if (_hasChecked) return;
              setState(() {
                _slotContents[slotId] = null;
              });
            },
            child: _buildChoiceChip(placedValue, isSlottedStyle: true),
          );
        } else {
          // Render dashed border empty target
          return Container(
            height: 38,
            constraints: const BoxConstraints(minWidth: 70),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFB0BAC5),
                width: 1.5,
                style: BorderStyle.solid, // Flat solid thin border (clean dashed look simulation)
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              placeholder,
              style: GoogleFonts.nunito(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      },
      onWillAcceptWithDetails: (details) => _slotContents[slotId] == null && !_hasChecked,
      onAcceptWithDetails: (details) {
        setState(() {
          // Clear it from previous slots if dragged
          _slotContents.forEach((key, val) {
            if (val == details.data) _slotContents[key] = null;
          });
          _slotContents[slotId] = details.data;
        });
      },
    );
  }

  // Choice chip styling with responsive syntax colors
  Widget _buildChoiceChip(
    String text, {
    bool isPlaced = false,
    bool isDragging = false,
    bool isSlottedStyle = false,
  }) {
    final colors = getChipColors(text);

    return Opacity(
      opacity: isPlaced ? 0.25 : 1.0,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.shadowColor, width: 1.5),
          boxShadow: isDragging || isSlottedStyle
              ? null
              : [
                  BoxShadow(
                    color: colors.shadowColor.withValues(alpha: 0.5),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Text(
          text,
          style: GoogleFonts.firaCode(
            color: colors.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // Bottom feedback sheet
  Widget _buildBottomActionBar() {
    if (!_hasChecked) {
      // Regular Run Code panel
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E4EC), width: 1.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 145,
              child: Duo3dButton(
                faceColor: const Color(0xFF58CC02),
                shadowColor: const Color(0xFF439E00),
                height: 48,
                onPressed: _onRunCode,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 4),
                    Text(
                      "Run Code",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Result panel sliding up
      final Color barBgColor = _isCorrect ? const Color(0xFFD6F6E6) : const Color(0xFFFDECEE);
      final Color textColor = _isCorrect ? const Color(0xFF0F9F59) : const Color(0xFFE55353);
      final String headerText = _isCorrect ? "EXCELLENT!" : "CORRECT SOLUTION:";
      
      // Get correct answers code representation
      final question = _questions[_currentQuestionIndex];
      final List<String> correctSegments = [];
      for (var slotId in question.correctAnswers.keys) {
        correctSegments.add(question.correctAnswers[slotId] ?? "");
      }
      final String correctCodeMsg = correctSegments.join(" ");

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: barBgColor,
          border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.3), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: textColor,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  headerText,
                  style: GoogleFonts.nunito(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (!_isCorrect) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100, width: 1),
                ),
                child: Text(
                  correctCodeMsg,
                  style: GoogleFonts.firaCode(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Duo3dButton(
              faceColor: textColor,
              shadowColor: _isCorrect ? const Color(0xFF0C8A4C) : const Color(0xFFC03C3C),
              height: 50,
              onPressed: _onContinue,
              child: Text(
                _isCorrect ? "CONTINUE" : "GOT IT",
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  ChipColors getChipColors(String text) {
    if (text.startsWith('"') ||
        text.endsWith('"') ||
        text.startsWith("'") ||
        text.endsWith("'") ||
        int.tryParse(text) != null) {
      // String literals or numbers -> Blue
      return ChipColors(
        bgColor: const Color(0xFFD2EBFD),
        textColor: const Color(0xFF1C83B4),
        shadowColor: const Color(0xFFA1D1FA),
      );
    } else if (text.contains('(') ||
        text == 'if' ||
        text == 'else' ||
        text == 'else:' ||
        text == 'elif' ||
        text == 'while' ||
        text == 'for' ||
        text == 'in' ||
        text == 'const' ||
        text == 'let' ||
        text == 'var' ||
        text == 'int' ||
        text == 'double' ||
        text == 'String' ||
        text == '#include' ||
        text == 'std::' ||
        text == 'System.') {
      // Keywords / function calls -> Purple
      return ChipColors(
        bgColor: const Color(0xFFE6D6FD),
        textColor: const Color(0xFF894CE6),
        shadowColor: const Color(0xFFC1A8F9),
      );
    } else {
      // Operators / parameters -> Green
      return ChipColors(
        bgColor: const Color(0xFFD6F6E6),
        textColor: const Color(0xFF0E9E58),
        shadowColor: const Color(0xFF9EE4BF),
      );
    }
  }
}

class ChipColors {
  final Color bgColor;
  final Color textColor;
  final Color shadowColor;
  ChipColors({
    required this.bgColor,
    required this.textColor,
    required this.shadowColor,
  });
}
