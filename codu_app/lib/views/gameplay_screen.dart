import 'dart:math';
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
  final Set<String> _incorrectSlots = {};

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
    AudioService().playMusic('Audio/Menu Music.mp3');
    super.dispose();
  }



  void _clearSlots() {
    _slotContents.clear();
    _incorrectSlots.clear();
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
    _incorrectSlots.clear();
    _slotContents.forEach((slotId, valueIndex) {
      if (valueIndex == null) {
        correct = false;
      } else {
        final choiceValue = question.choices[valueIndex];
        if (question.correctAnswers[slotId] != choiceValue) {
          correct = false;
          _incorrectSlots.add(slotId);
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
      _showGameOverScreen();
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
                            GameStarsPopup(earnedStars: earnedStars),
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
              // Falling Confetti Overlay
              const Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiFallingWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameOverScreen() {
    AudioService().stopMusic();
    AudioService().playSfx('Audio/CompletedLose.mp3');

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
                        "You LOSE!",
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
                            const SizedBox(height: 16),
                            // Mascot Robot 404
                            SvgPicture.asset(
                              'assets/images/CoduExpression/codu 404.svg',
                              width: 180,
                              height: 180,
                            ),
                            const SizedBox(height: 24),
                            // Title
                            Text(
                              "Try again!",
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1E2A38),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Subtitle
                            Text(
                              "Dont lose your all of your health",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF9AAEC4),
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Retry Level 3D Button
                            Duo3dButton(
                              faceColor: const Color(0xFFFFB020),
                              shadowColor: const Color(0xFFD48C00),
                              height: 52,
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => GameplayScreen(
                                      levelNumber: widget.levelNumber,
                                      subject: widget.subject,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "Retry level",
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
                                    border: _hasChecked && !_isCorrect
                                        ? Border.all(color: const Color(0xFFE55353), width: 2)
                                        : null,
                                    boxShadow: _hasChecked && !_isCorrect
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFE55353).withValues(alpha: 0.15),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
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
        final bool hasErrorInLine = line.any((segment) => segment.isSlot && _incorrectSlots.contains(segment.text));

        final Widget lineWidget = Padding(
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

        if (hasErrorInLine) {
          // Calculate approx left offset for the incorrect slot to align the speech bubble's tail
          double approxLeftOffset = 0.0;
          for (var segment in line) {
            if (segment.isSlot && _incorrectSlots.contains(segment.text)) {
              break;
            }
            if (segment.isSlot) {
              approxLeftOffset += 80.0;
            } else {
              final String text = segment.text;
              if (text.startsWith("    ")) {
                final int spacesCount = text.length - text.trimLeft().length;
                final double indentWidth = (spacesCount / 4) * 20.0;
                approxLeftOffset += indentWidth + (text.trimLeft().length * 8.5);
              } else {
                approxLeftOffset += text.length * 8.5;
              }
            }
            approxLeftOffset += 4.0; // spacing
          }

          // Center of the slot: approxLeftOffset + 40.0
          final double tailX = approxLeftOffset + 40.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              lineWidget,
              const SizedBox(height: 4),
              SpeechBubble(
                tailX: tailX,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/CoduExpression/codu 404.svg',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: const Color(0xFF2C3E50),
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(
                              text: "Oops! ",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const TextSpan(
                              text: "That's not correct. Try checking your commands agains.",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
          );
        }

        return lineWidget;
      }).toList(),
    );
  }

  // Dashed border or filled slot target
  Widget _buildSlotTarget(String slotId, String placeholder) {
    final int? placedIndex = _slotContents[slotId];
    final question = _questions[_currentQuestionIndex];
    final bool isIncorrect = _hasChecked && _incorrectSlots.contains(slotId);

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
            child: _buildChoiceChip(placedValue, isSlottedStyle: true, isIncorrect: isIncorrect),
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
    bool isIncorrect = false,
  }) {
    if (isIncorrect) {
      final chipContent = Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEE), // light pink
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE55353), width: 1.5),
        ),
        child: Text(
          text,
          style: GoogleFonts.firaCode(
            color: const Color(0xFFE55353), // red
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

      return Stack(
        clipBehavior: Clip.none,
        children: [
          chipContent,
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFE55353),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
    } else if (!_isCorrect) {
      // Checked and incorrect state -> terracotta centered button
      final bool isDead = _hearts <= 0;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E4EC), width: 1.5)),
        ),
        child: Center(
          child: SizedBox(
            width: 260,
            child: Duo3dButton(
              faceColor: const Color(0xFFE55353),
              shadowColor: const Color(0xFFC03C3C),
              height: 48,
              onPressed: () {
                if (isDead) {
                  _showGameOverScreen();
                } else {
                  setState(() {
                    _hasChecked = false;
                    _incorrectSlots.clear();
                  });
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isDead ? Icons.arrow_forward_rounded : Icons.refresh_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isDead ? "Continue" : "Check Code Again",
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
        ),
      );
    } else {
      // Correct answer state -> original green sliding-up panel
      final Color barBgColor = const Color(0xFFD6F6E6);
      final Color textColor = const Color(0xFF0F9F59);
      final String headerText = "EXCELLENT!";

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
                  Icons.check_circle_rounded,
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
            const SizedBox(height: 20),
            Duo3dButton(
              faceColor: textColor,
              shadowColor: const Color(0xFF0C8A4C),
              height: 50,
              onPressed: _onContinue,
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

class GameStarsPopup extends StatefulWidget {
  final int earnedStars;
  const GameStarsPopup({super.key, required this.earnedStars});

  @override
  State<GameStarsPopup> createState() => _GameStarsPopupState();
}

class _GameStarsPopupState extends State<GameStarsPopup> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      );
    }).toList();

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      await Future.delayed(Duration(milliseconds: i == 0 ? 100 : 250));
      if (!mounted) return;
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double containerWidth = 260.0;
    const double containerHeight = 180.0;

    return SizedBox(
      width: containerWidth,
      height: containerHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Left Star
          Positioned(
            left: 0,
            bottom: 8,
            child: ScaleTransition(
              scale: _animations[0],
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  Icons.star_rounded,
                  size: 110,
                  color: widget.earnedStars >= 1 ? const Color(0xFFFFD600) : const Color(0xFFE0E4EC),
                ),
              ),
            ),
          ),
          // Right Star
          Positioned(
            right: 0,
            bottom: 8,
            child: ScaleTransition(
              scale: _animations[2],
              child: Transform.rotate(
                angle: 0.2,
                child: Icon(
                  Icons.star_rounded,
                  size: 110,
                  color: widget.earnedStars >= 3 ? const Color(0xFFFFD600) : const Color(0xFFE0E4EC),
                ),
              ),
            ),
          ),
          // Center Star (rendered last to appear on top of outer stars)
          Positioned(
            left: (containerWidth - 154) / 2,
            bottom: 20,
            child: ScaleTransition(
              scale: _animations[1],
              child: Icon(
                Icons.star_rounded,
                size: 154,
                color: widget.earnedStars >= 2 ? const Color(0xFFFFD600) : const Color(0xFFE0E4EC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CONFETTI SYSTEM ---

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  Color color;
  double width;
  double height;
  bool isCircle;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.width,
    required this.height,
    required this.isCircle,
  });
}

class ConfettiFallingWidget extends StatefulWidget {
  const ConfettiFallingWidget({super.key});

  @override
  State<ConfettiFallingWidget> createState() => _ConfettiFallingWidgetState();
}

class _ConfettiFallingWidgetState extends State<ConfettiFallingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();
  bool _shouldSpawn = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..addListener(() {
        _updateParticles();
      });

    _controller.repeat();

    // Stop spawning new particles after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _shouldSpawn = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty) {
      final size = MediaQuery.of(context).size;
      final colors = [
        const Color(0xFFFFD56B), // Yellow
        const Color(0xFFFF8B8B), // Red/Pink
        const Color(0xFF8F93EA), // Purple
        const Color(0xFF7A9EFF), // Blue
        const Color(0xFF8CEEAD), // Green
        const Color(0xFFFFC5A5), // Orange
      ];

      for (int i = 0; i < 80; i++) {
        _particles.add(ConfettiParticle(
          x: _random.nextDouble() * size.width,
          y: -_random.nextDouble() * size.height * 1.5 - 20,
          vx: (_random.nextDouble() - 0.5) * 2.0,
          vy: _random.nextDouble() * 4.0 + 2.0,
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
          color: colors[_random.nextInt(colors.length)],
          width: _random.nextDouble() * 6 + 6,
          height: _random.nextDouble() * 12 + 8,
          isCircle: _random.nextBool(),
        ));
      }
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    bool anyVisible = false;
    for (var p in _particles) {
      p.y += p.vy;
      p.x += p.vx;
      p.rotation += p.rotationSpeed;
      if (p.y > size.height) {
        if (_shouldSpawn) {
          p.y = -20.0;
          p.x = _random.nextDouble() * size.width;
          anyVisible = true;
        }
      } else {
        if (p.y <= size.height) {
          anyVisible = true;
        }
      }
    }
    
    // If no particles are visible anymore, stop the loop to conserve resources
    if (!anyVisible && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(particles: _particles),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      if (p.y < -20 || p.y > size.height) continue;
      paint.color = p.color;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.isCircle) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: p.width, height: p.height),
          paint,
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.width, height: p.height),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

class SpeechBubble extends StatelessWidget {
  final double tailX;
  final Widget child;

  const SpeechBubble({
    super.key,
    required this.tailX,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SpeechBubblePainter(
        tailX: tailX,
        fillColor: const Color(0xFFFEECEB), // light peach/pink
        borderColor: const Color(0xFFE55353), // red
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10.0 + 12.0, // tailHeight + body padding top
          bottom: 12.0,
          left: 14.0,
          right: 14.0,
        ),
        child: child,
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  final double tailX;
  final double tailWidth;
  final double tailHeight;
  final double borderRadius;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  SpeechBubblePainter({
    required this.tailX,
    this.tailWidth = 16.0,
    this.tailHeight = 10.0,
    this.borderRadius = 16.0,
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;
    final double R = borderRadius;
    final double Th = tailHeight;
    final double Tw = tailWidth;
    final double Tx = tailX.clamp(R + Tw / 2, W - R - Tw / 2);

    final Path path = Path();
    
    // Start at top-left corner start point
    path.moveTo(R, Th);
    
    // Top line to tail start
    path.lineTo(Tx - Tw / 2, Th);
    // Tail tip
    path.lineTo(Tx, 0);
    // Tail end
    path.lineTo(Tx + Tw / 2, Th);
    // Top line to top-right
    path.lineTo(W - R, Th);
    
    // Top-right corner
    path.arcToPoint(
      Offset(W, Th + R),
      radius: Radius.circular(R),
      clockwise: true,
    );
    
    // Right side
    path.lineTo(W, H - R);
    
    // Bottom-right corner
    path.arcToPoint(
      Offset(W - R, H),
      radius: Radius.circular(R),
      clockwise: true,
    );
    
    // Bottom side
    path.lineTo(R, H);
    
    // Bottom-left corner
    path.arcToPoint(
      Offset(0, H - R),
      radius: Radius.circular(R),
      clockwise: true,
    );
    
    // Left side
    path.lineTo(0, Th + R);
    
    // Top-left corner
    path.arcToPoint(
      Offset(R, Th),
      radius: Radius.circular(R),
      clockwise: true,
    );
    
    path.close();

    // Paint fill
    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Paint border/stroke
    final Paint strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant SpeechBubblePainter oldDelegate) {
    return oldDelegate.tailX != tailX ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
