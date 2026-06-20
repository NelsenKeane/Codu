import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';
import '../services/user_data_service.dart';
import '../widgets/skeleton_loader.dart';
import 'gameplay_screen.dart';

class CachedSvgMapData {
  final String svgContent;
  final PathMetric pathMetric;
  CachedSvgMapData({required this.svgContent, required this.pathMetric});
}

class LevelsScreen extends StatefulWidget {
  final String? initialSubject;
  const LevelsScreen({super.key, this.initialSubject});

  // Public static cache map
  static final Map<String, CachedSvgMapData> svgCache = {};
  static final Map<String, int> completedCache = {};
  static final Map<String, Map<int, int>> starsCache = {};

  static Future<void> preloadMaps() async {
    final subjects = ['Phyton', 'C++', 'Javascript', 'Java'];
    for (var subject in subjects) {
      String svgPath = '';
      switch (subject) {
        case 'Phyton':
          svgPath = 'assets/images/Level Map 1.svg';
          break;
        case 'C++':
          svgPath = 'assets/images/Level Map 2.svg';
          break;
        case 'Javascript':
          svgPath = 'assets/images/Level Map 3.svg';
          break;
        case 'Java':
          svgPath = 'assets/images/Level Map 4.svg';
          break;
      }

      if (svgCache.containsKey(svgPath)) continue;

      try {
        String svgString = await rootBundle.loadString(svgPath);

        // Extend starting point
        final RegExp pathStartRegex = RegExp(r'd="M([0-9.]+),11000v-([0-9.]+)');
        String modifiedSvgPath = svgString.replaceFirstMapped(pathStartRegex, (match) {
          final double x = double.parse(match.group(1)!);
          final double vDistance = double.parse(match.group(2)!);
          final double newVDistance = vDistance + 400.0;
          return 'd="M$x,11400v-$newVDistance';
        });

        // Curvy extension
        double xStart = 613.94;
        if (svgPath.contains('Map 2')) {
          xStart = 770.0;
        } else if (svgPath.contains('Map 3') || svgPath.contains('Map 4')) {
          xStart = 600.0;
        }

        StringBuffer sb = StringBuffer();
        double currentY = 0;
        double w1 = xStart - 211.81;
        double hSegment1 = w1 - 307.92;
        sb.write('v-50c0-85.03,-68.93-153.96,-153.96-153.96h-${hSegment1.toStringAsFixed(2)}c-85.03,0,-153.96-68.93,-153.96-153.96v-50');
        currentY -= 407.92;

        bool goRight = true;
        while (currentY > -5000) {
          if (goRight) {
            sb.write('v-50c0-85.03,68.93-153.96,153.96-153.96h349.28c85.03,0,153.96-68.93,153.96-153.96v-50');
          } else {
            sb.write('v-50c0-85.03,-68.93-153.96,-153.96-153.96h-349.28c-85.03,0,-153.96-68.93,-153.96-153.96v-50');
          }
          currentY -= 407.92;
          goRight = !goRight;
        }
        final String curvyExtension = '${sb.toString()}"';
        modifiedSvgPath = modifiedSvgPath.replaceFirst('V0"', curvyExtension);

        PathMetric? pathMetric;
        RegExp regExp = RegExp(r'\bd="([^"]+)"');
        var match = regExp.firstMatch(modifiedSvgPath);
        if (match != null) {
          String pathData = match.group(1)!;
          Path path = parseSvgPathData(pathData);
          var metrics = path.computeMetrics().toList();
          if (metrics.isNotEmpty) {
            pathMetric = metrics.first;
          }
        }

        // Remove style block
        final RegExp styleRegex = RegExp(r'<style>.*?</style>', dotAll: true);
        String cleanedSvg = svgString.replaceAll(styleRegex, '');

        cleanedSvg = cleanedSvg.replaceAll('viewBox="0 0 1080 11000"', 'viewBox="0 -5000 1080 16400"');

        cleanedSvg = cleanedSvg.replaceFirstMapped(pathStartRegex, (match) {
          final double x = double.parse(match.group(1)!);
          final double vDistance = double.parse(match.group(2)!);
          final double newVDistance = vDistance + 400.0;
          return 'd="M$x,11400v-$newVDistance';
        });

        cleanedSvg = cleanedSvg.replaceFirst('V0"', curvyExtension);

        cleanedSvg = cleanedSvg.replaceFirst(
          '<use transform="scale(.71)" xlink:href="#image"/>',
          '<use transform="translate(0 -6453.09) scale(.71)" xlink:href="#image"/>\n    <use transform="translate(0 -4302.06) scale(.71)" xlink:href="#image"/>\n    <use transform="translate(0 -2151.03) scale(.71)" xlink:href="#image"/>\n    <use transform="scale(.71)" xlink:href="#image"/>'
        );

        cleanedSvg = cleanedSvg.replaceFirst(
          '<image width="1520" height="352" transform="translate(0 10765.9) scale(.71)"',
          '<use transform="translate(0 10765.9) scale(.71)" xlink:href="#image"/>\n    <image width="1520" height="352" transform="translate(0 11150) scale(.71)"'
        );

        String svgContent = cleanedSvg
            .replaceAll('class="st0"', 'fill="#ffffff" stroke="#231f20" stroke-miterlimit="10"')
            .replaceAll('class="st1"', 'fill="none" stroke="#8dd5e6" stroke-width="150" stroke-miterlimit="10" filter="url(#drop-shadow-1)"');

        if (pathMetric != null) {
          svgCache[svgPath] = CachedSvgMapData(
            svgContent: svgContent,
            pathMetric: pathMetric,
          );
        }
      } catch (e) {
        debugPrint("Error preloading SVG path for $subject: $e");
      }
    }

    // Preload user progress for all subjects into static cache
    try {
      final history = await UserDataService().getHistory();
      for (var h in history) {
        final lang = h['lang'] as String;
        final completed = h['completed'] as int? ?? 0;
        completedCache[lang] = completed;
      }
      for (var subject in subjects) {
        final dbSubject = subject == 'Phyton' ? 'Python' : subject;
        final starsMap = await UserDataService().getLevelStars(dbSubject);
        starsCache[dbSubject] = starsMap;
      }
    } catch (e) {
      debugPrint("Error preloading user progress for levels: $e");
    }
  }

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> with SingleTickerProviderStateMixin {
  String _selectedSubject = 'Phyton'; // Mockup spelling

  final List<String> _subjects = ['Phyton', 'C++', 'Javascript', 'Java'];

  int _streak = 0;
  int _trophies = 0;
  bool _isLoading = true;

  // SVG & Animation State variables
  final ScrollController _scrollController = ScrollController();
  AnimationController? _animationController;
  Animation<double>? _animation;

  PathMetric? _pathMetric;
  List<Offset> _nodePositions = [];
  double _scale = 1.0;
  double _canvasHeight = 16400.0;
  String _svgContent = '';
  int _activeLevelIndex = 2; // Will be calculated from DB progress
  Map<int, int> _levelStarsMap = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSubject != null) {
      String subject = widget.initialSubject!;
      if (subject == 'Python') {
        subject = 'Phyton';
      }
      _selectedSubject = subject;
    }
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant LevelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubject != null && widget.initialSubject != oldWidget.initialSubject) {
      String subject = widget.initialSubject!;
      if (subject == 'Python') {
        subject = 'Phyton';
      }
      setState(() {
        _selectedSubject = subject;
      });
      _loadSvgPath();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData({bool forceReload = false}) async {
    final streak = await UserDataService().getStreak();
    final trophies = await UserDataService().getTrophies();
    if (mounted) {
      setState(() {
        _streak = streak;
        _trophies = trophies;
      });
      await _loadSvgPath(forceReload: forceReload);
    }
  }

  String _getSvgPath() {
    switch (_selectedSubject) {
      case 'Phyton':
        return 'assets/images/Level Map 1.svg';
      case 'C++':
        return 'assets/images/Level Map 2.svg';
      case 'Javascript':
        return 'assets/images/Level Map 3.svg';
      case 'Java':
        return 'assets/images/Level Map 4.svg';
      default:
        return 'assets/images/Level Map 1.svg';
    }
  }

  void _scrollToBottomAndAnimate() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      double scale = MediaQuery.of(context).size.width / 1080.0;
      double canvasHeight = 16400.0 * scale;
      double maxScroll = canvasHeight - MediaQuery.of(context).size.height;
      if (maxScroll > 0) {
        _scrollController.jumpTo(maxScroll);
      }
    }
    _startAnimation();
  }

  Future<void> _loadSvgPath({bool forceReload = false}) async {
    final dbSubject = _selectedSubject == 'Phyton' ? 'Python' : _selectedSubject;
    String svgPath = _getSvgPath();

    // Check synchronous cache path first
    if (!forceReload &&
        LevelsScreen.svgCache.containsKey(svgPath) &&
        LevelsScreen.completedCache.containsKey(dbSubject) &&
        LevelsScreen.starsCache.containsKey(dbSubject)) {
      
      final cached = LevelsScreen.svgCache[svgPath]!;
      final completed = LevelsScreen.completedCache[dbSubject]!;
      final starsMap = LevelsScreen.starsCache[dbSubject]!;

      _svgContent = cached.svgContent;
      _pathMetric = cached.pathMetric;
      _levelStarsMap = starsMap;
      _activeLevelIndex = completed.clamp(0, 44);
      _isLoading = false;

      // Jump and animate after rendering
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottomAndAnimate();
      });
      return;
    }

    // Only show skeleton loader if we don't have SVG content yet
    if (_svgContent.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final history = await UserDataService().getHistory();
      for (var h in history) {
        final lang = h['lang'] as String;
        final completed = h['completed'] as int? ?? 0;
        LevelsScreen.completedCache[lang] = completed;
      }

      final starsMap = await UserDataService().getLevelStars(dbSubject);
      LevelsScreen.starsCache[dbSubject] = starsMap;

      final subjectProgress = history.firstWhere(
        (h) => h['lang'] == dbSubject,
        orElse: () => <String, dynamic>{},
      );

      int completed = 0;
      if (subjectProgress.isNotEmpty) {
        completed = subjectProgress['completed'] ?? 0;
      }
      
      setState(() {
        _levelStarsMap = starsMap;
        _activeLevelIndex = completed.clamp(0, 44);
      });

      // Check cache again for SVG
      if (LevelsScreen.svgCache.containsKey(svgPath)) {
        final cached = LevelsScreen.svgCache[svgPath]!;
        _svgContent = cached.svgContent;
        _pathMetric = cached.pathMetric;
      } else {
        String svgString = await rootBundle.loadString(svgPath);

        // Extend starting point
        final RegExp pathStartRegex = RegExp(r'd="M([0-9.]+),11000v-([0-9.]+)');
        String modifiedSvgPath = svgString.replaceFirstMapped(pathStartRegex, (match) {
          final double x = double.parse(match.group(1)!);
          final double vDistance = double.parse(match.group(2)!);
          final double newVDistance = vDistance + 400.0;
          return 'd="M$x,11400v-$newVDistance';
        });

        // Curvy extension
        final String curvyExtension = _generateCurvyExtension(svgPath: svgPath);
        modifiedSvgPath = modifiedSvgPath.replaceFirst('V0"', curvyExtension);

        PathMetric? pathMetric;
        RegExp regExp = RegExp(r'\bd="([^"]+)"');
        var match = regExp.firstMatch(modifiedSvgPath);
        if (match != null) {
          String pathData = match.group(1)!;
          Path path = parseSvgPathData(pathData);
          var metrics = path.computeMetrics().toList();
          if (metrics.isNotEmpty) {
            pathMetric = metrics.first;
          }
        }

        // Remove style block
        final RegExp styleRegex = RegExp(r'<style>.*?</style>', dotAll: true);
        String cleanedSvg = svgString.replaceAll(styleRegex, '');

        cleanedSvg = cleanedSvg.replaceAll('viewBox="0 0 1080 11000"', 'viewBox="0 -5000 1080 16400"');

        cleanedSvg = cleanedSvg.replaceFirstMapped(pathStartRegex, (match) {
          final double x = double.parse(match.group(1)!);
          final double vDistance = double.parse(match.group(2)!);
          final double newVDistance = vDistance + 400.0;
          return 'd="M$x,11400v-$newVDistance';
        });

        cleanedSvg = cleanedSvg.replaceFirst('V0"', curvyExtension);

        cleanedSvg = cleanedSvg.replaceFirst(
          '<use transform="scale(.71)" xlink:href="#image"/>',
          '<use transform="translate(0 -6453.09) scale(.71)" xlink:href="#image"/>\n    <use transform="translate(0 -4302.06) scale(.71)" xlink:href="#image"/>\n    <use transform="translate(0 -2151.03) scale(.71)" xlink:href="#image"/>\n    <use transform="scale(.71)" xlink:href="#image"/>'
        );

        cleanedSvg = cleanedSvg.replaceFirst(
          '<image width="1520" height="352" transform="translate(0 10765.9) scale(.71)"',
          '<use transform="translate(0 10765.9) scale(.71)" xlink:href="#image"/>\n    <image width="1520" height="352" transform="translate(0 11150) scale(.71)"'
        );

        _svgContent = cleanedSvg
            .replaceAll('class="st0"', 'fill="#ffffff" stroke="#231f20" stroke-miterlimit="10"')
            .replaceAll('class="st1"', 'fill="none" stroke="#8dd5e6" stroke-width="150" stroke-miterlimit="10" filter="url(#drop-shadow-1)"');

        _pathMetric = pathMetric;

        // Save to cache
        if (_pathMetric != null) {
          LevelsScreen.svgCache[svgPath] = CachedSvgMapData(
            svgContent: _svgContent,
            pathMetric: _pathMetric!,
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading or parsing SVG path: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottomAndAnimate();
        });
      }
    }
  }

  Widget _buildLevelsMapSkeleton() {
    return Container(
      color: const Color(0xFF56CCF2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            final double alignX = index % 2 == 0 ? -0.5 : 0.5;
            return Align(
              alignment: Alignment(alignX, 0),
              child: const SkeletonLoader(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _updatePathPositions(double screenWidth) {
    if (_pathMetric == null) return;
    _scale = screenWidth / 1080.0;
    _canvasHeight = 16400.0 * _scale;

    double totalLength = _pathMetric!.length;
    double startOffset = 550.0;
    double endOffset = 1800.0;
    double usableLength = totalLength - startOffset - endOffset;

    List<Offset> positions = [];
    for (int i = 0; i < 45; i++) {
      double distance = startOffset + i * (usableLength / 44.0);
      Tangent? tangent = _pathMetric!.getTangentForOffset(distance);
      if (tangent != null) {
        // Shift y-coordinate by 5000 to match viewBox shift (starts at y = -5000)
        positions.add(Offset(tangent.position.dx * _scale, (tangent.position.dy + 5000.0) * _scale));
      } else {
        positions.add(Offset(screenWidth / 2, (11000.0 - (startOffset + i * (usableLength / 44.0)) + 5000.0) * _scale));
      }
    }
    _nodePositions = positions;
  }

  void _startAnimation() {
    if (_pathMetric == null) return;
    double totalLength = _pathMetric!.length;
    double startOffset = 550.0;
    double endOffset = 1800.0;
    double usableLength = totalLength - startOffset - endOffset;
    double targetDistance = startOffset + _activeLevelIndex * (usableLength / 44.0);

    _animationController?.dispose();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: startOffset,
      end: targetDistance,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutCubic,
    ))
      ..addListener(() {
        setState(() {});
      });

    _animationController!.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveLevel();
    });
  }

  void _scrollToActiveLevel() {
    if (!mounted || _nodePositions.isEmpty || _activeLevelIndex >= _nodePositions.length) return;
    double nodeY = _nodePositions[_activeLevelIndex].dy;
    double targetScroll = nodeY - (MediaQuery.of(context).size.height / 2);

    double scale = MediaQuery.of(context).size.width / 1080.0;
    double canvasHeight = 16400.0 * scale;
    double maxScroll = canvasHeight - MediaQuery.of(context).size.height;
    if (maxScroll < 0) maxScroll = 0;
    targetScroll = targetScroll.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOutCubic,
    );
  }

  String _generateCurvyExtension({required String svgPath}) {
    double xStart = 613.94; // Default for Map 1
    if (svgPath.contains('Map 2')) {
      xStart = 770.0;
    } else if (svgPath.contains('Map 3') || svgPath.contains('Map 4')) {
      xStart = 600.0;
    }

    StringBuffer sb = StringBuffer();
    double currentY = 0;

    // First Turn: Go Left from xStart to 211.81
    double w1 = xStart - 211.81;
    double hSegment1 = w1 - 307.92;
    sb.write('v-50c0-85.03,-68.93-153.96,-153.96-153.96h-${hSegment1.toStringAsFixed(2)}c-85.03,0,-153.96-68.93,-153.96-153.96v-50');
    currentY -= 407.92;

    // Subsequent turns: wiggle between 211.81 and 869.01 (width 657.2)
    bool goRight = true;
    while (currentY > -5000) {
      if (goRight) {
        sb.write('v-50c0-85.03,68.93-153.96,153.96-153.96h349.28c85.03,0,153.96-68.93,153.96-153.96v-50');
      } else {
        sb.write('v-50c0-85.03,-68.93-153.96,-153.96-153.96h-349.28c-85.03,0,-153.96-68.93,-153.96-153.96v-50');
      }
      currentY -= 407.92;
      goRight = !goRight;
    }
    return '${sb.toString()}"';
  }

  void _showStreakDialog() {
    final TextEditingController controller = TextEditingController(text: _streak.toString());
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Update Streak",
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Update Streak Count",
                    style: GoogleFonts.nunito(
                      color: const Color(0xFF1D83B5),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 36, color: Colors.grey),
                        onPressed: () {
                          int val = int.tryParse(controller.text) ?? 0;
                          if (val > 0) {
                            controller.text = (val - 1).toString();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1D83B5),
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 36, color: Colors.green),
                        onPressed: () {
                          int val = int.tryParse(controller.text) ?? 0;
                          controller.text = (val + 1).toString();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.nunito(
                            color: Colors.grey,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB020),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          int? newStreak = int.tryParse(controller.text);
                          if (newStreak != null && newStreak >= 0) {
                            await UserDataService().saveStreak(newStreak);
                            _loadUserData();
                          }
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Save",
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTrophiesDialog() {
    final TextEditingController controller = TextEditingController(text: _trophies.toString());
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Update Trophies",
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Update Trophies Count",
                    style: GoogleFonts.nunito(
                      color: const Color(0xFF1D83B5),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 36, color: Colors.grey),
                        onPressed: () {
                          int val = int.tryParse(controller.text) ?? 0;
                          if (val > 0) {
                            controller.text = (val - 1).toString();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1D83B5),
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 36, color: Colors.green),
                        onPressed: () {
                          int val = int.tryParse(controller.text) ?? 0;
                          controller.text = (val + 1).toString();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.nunito(
                            color: Colors.grey,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB020),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          int? newTrophies = int.tryParse(controller.text);
                          if (newTrophies != null && newTrophies >= 0) {
                            await UserDataService().saveTrophies(newTrophies);
                            _loadUserData();
                          }
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Save",
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Map subjects to emojis for the dropdown
  String _getSubjectEmoji(String subject) {
    switch (subject) {
      case 'Phyton':
        return '🐍';
      case 'C++':
        return '🔵';
      case 'Javascript':
        return '💛';
      case 'Java':
        return '☕';
      default:
        return '📚';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Always compute canvas height proportionally — SVG viewBox is 1080×16400.
    // This guarantees the image is NEVER stretched regardless of device width.
    _scale = screenWidth / 1080.0;
    _canvasHeight = 16400.0 * _scale;

    if (!_isLoading && _pathMetric != null) {
      _updatePathPositions(screenWidth);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2),
      body: Stack(
        children: [
          // 1. Background Silhouettes (visible while loading)
          _buildBackgroundDecor(statusBarHeight),

          // 2. Scrollable Level Map
          Positioned.fill(
            child: _isLoading
                ? _buildLevelsMapSkeleton()
                : NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: (overscroll) {
                      overscroll.disallowIndicator();
                      return true;
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        // Width = screenWidth, Height = proportional to SVG aspect ratio
                        width: screenWidth,
                        height: _canvasHeight,
                        child: Stack(
                          children: [
                            // ── SVG background ──────────────────────────────
                            // fitWidth fills the full screen width and scales
                            // the height proportionally — no stretching ever.
                            Positioned.fill(
                              child: _svgContent.isNotEmpty
                                  ? SvgPicture.string(
                                      _svgContent,
                                      fit: BoxFit.fitWidth,
                                      alignment: Alignment.topCenter,
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // ── Animated player position marker ─────────────
                            // The SVG already draws the road; we only overlay
                            // the player circle and level nodes on top.
                            if (_pathMetric != null && _animation != null)
                              _buildAnimatedProgressMarker(),

                            // ── Level nodes along the path ──────────────────
                            ..._buildLevelNodes(screenWidth),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),

          // 3. Floating Header (Subject Selector & Stats)
          Positioned(
            top: statusBarHeight + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSubjectDropdown(),
                _buildStatsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgressMarker() {
    if (_pathMetric == null || _animation == null) return const SizedBox.shrink();

    double currentDistance = _animation!.value;
    Tangent? tangent = _pathMetric!.getTangentForOffset(currentDistance);
    if (tangent == null) return const SizedBox.shrink();

    double markerX = tangent.position.dx * _scale;
    double markerY = (tangent.position.dy + 5000.0) * _scale;
    const double markerSize = 36.0;

    return Positioned(
      left: markerX - (markerSize / 2),
      top: markerY - (markerSize / 2),
      child: Container(
        width: markerSize,
        height: markerSize,
        decoration: BoxDecoration(
          color: const Color(0xFFFFB020),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  // Floating background silhouettes for premium look
  Widget _buildBackgroundDecor(double statusBarHeight) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: statusBarHeight + 120,
            left: -20,
            child: Icon(
              Icons.code_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 350,
            right: -10,
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 90,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 600,
            left: 30,
            child: Icon(
              Icons.menu_book_rounded,
              size: 70,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 850,
            right: 40,
            child: Icon(
              Icons.code_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 1100,
            left: -15,
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 1300,
            right: 20,
            child: Icon(
              Icons.terminal_rounded,
              size: 60,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  // Purple pill-shaped dropdown for selecting subjects
  Widget _buildSubjectDropdown() {
    return PopupMenuButton<String>(
      onSelected: (String val) {
        if (_selectedSubject != val) {
          setState(() {
            _selectedSubject = val;
          });
          _loadSvgPath();
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      offset: const Offset(0, 50),
      itemBuilder: (BuildContext context) {
        return _subjects.map((String subject) {
          return PopupMenuItem<String>(
            value: subject,
            child: Row(
              children: [
                Text(
                  _getSubjectEmoji(subject),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  subject,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8F93EA), Color(0xFF7076E3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7076E3).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getSubjectEmoji(_selectedSubject),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedSubject,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // Row for streak (fire) and stars stats
  Widget _buildStatsRow() {
    return Row(
      children: [
        // Streak / Fire Capsule
        GestureDetector(
          onTap: _showStreakDialog,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF3F4D59), // Dark slate background
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
              children: [
                const Text(
                  "🔥",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  "$_streak",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Star Capsule
        GestureDetector(
          onTap: _showTrophiesDialog,
          child: Container(
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
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFD56B), // Golden yellow star
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  "$_trophies",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Generates the level nodes positioned along the winding path from metrics
  List<Widget> _buildLevelNodes(double screenWidth) {
    if (_nodePositions.isEmpty) return [];

    final List<Map<String, dynamic>> levels = [];
    for (int i = 44; i >= 0; i--) {
      int levelNum = i + 1;
      String type;
      int stars = 0;

      if (i < _activeLevelIndex) {
        type = 'completed';
        stars = _levelStarsMap[levelNum] ?? 3;
      } else if (i == _activeLevelIndex) {
        type = 'active';
      } else {
        if (levelNum == 45) {
          type = 'crown';
        } else {
          type = 'locked';
        }
      }

      levels.add({
        'level': levelNum,
        'type': type,
        'stars': stars,
        'posIndex': i,
      });
    }

    return levels.map((level) {
      final int posIndex = level['posIndex'];
      final Offset pos = _nodePositions[posIndex];
      final String type = level['type'];
      final int levelNum = level['level'];
      final bool isExam = levelNum % 6 == 0;
      const double nodeSize = 72.0;

      Widget nodeChild;
      if (type == 'completed') {
        nodeChild = LevelNodeCompleted(stars: level['stars'], isExam: isExam);
      } else if (type == 'active') {
        nodeChild = LevelNodeActive(levelNumber: levelNum, isExam: isExam);
      } else if (type == 'crown') {
        nodeChild = const LevelNodeCrown();
      } else {
        nodeChild = LevelNodeLocked(isExam: isExam);
      }

      final double boxWidth = nodeSize + 40;
      final double boxHeight = nodeSize + 60;

      final bool isPlayable = type == 'active' || type == 'completed';

      return Positioned(
        left: pos.dx - (boxWidth / 2),
        top: pos.dy - (boxHeight / 2),
        child: GestureDetector(
          onTap: () {
            if (isPlayable) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GameplayScreen(
                    levelNumber: levelNum,
                    subject: _selectedSubject,
                  ),
                ),
              ).then((_) {
                _loadUserData(forceReload: true);
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("This level is locked! Complete the previous levels first."),
                  backgroundColor: Color(0xFFE55353),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                nodeChild,
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

// Custom Painter to draw the active progress highlight along the parsed SVG path
class WindingPathPainter extends CustomPainter {
  final PathMetric? pathMetric;
  final double currentDistance;
  final double scale;

  WindingPathPainter({
    required this.pathMetric,
    required this.currentDistance,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pathMetric == null || currentDistance <= 0) return;

    // Extract the path from 0.0 to currentDistance
    Path extractPath = pathMetric!.extractPath(0.0, currentDistance);

    // Apply the scale to the path using a Float64List scale matrix
    final Float64List scaleMatrix = Float64List(16);
    scaleMatrix[0] = scale;  // sx
    scaleMatrix[5] = scale;  // sy
    scaleMatrix[10] = 1.0;   // sz
    scaleMatrix[15] = 1.0;   // w
    final Path scaledPath = extractPath.transform(scaleMatrix);

    // Draw the active path highlight ribbon in a premium golden yellow color
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFD56B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36.0 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(scaledPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant WindingPathPainter oldDelegate) {
    return oldDelegate.currentDistance != currentDistance ||
        oldDelegate.pathMetric != pathMetric ||
        oldDelegate.scale != scale;
  }
}

// ---------------- LEVEL NODES COMPONENT WIDGETS ----------------

// Base structure for 3D circular button used by nodes
class Duo3dCircleButton extends StatefulWidget {
  final Widget child;
  final Color faceColor;
  final Color shadowColor;
  final VoidCallback? onPressed;
  final double size;

  const Duo3dCircleButton({
    super.key,
    required this.child,
    required this.faceColor,
    required this.shadowColor,
    this.onPressed,
    this.size = 72,
  });

  @override
  State<Duo3dCircleButton> createState() => _Duo3dCircleButtonState();
}

class _Duo3dCircleButtonState extends State<Duo3dCircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double shadowHeight = 6.0;
    final double translation = _isPressed ? shadowHeight : 0;

    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: widget.onPressed == null ? null : () => setState(() => _isPressed = false),
      child: Container(
        width: widget.size,
        height: widget.size + shadowHeight,
        decoration: BoxDecoration(
          color: widget.shadowColor,
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              top: translation,
              left: 0,
              right: 0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.faceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
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

// 1. Completed Node (Yellow Circle, checkmark inside, stars above)
class LevelNodeCompleted extends StatelessWidget {
  final int stars;
  final bool isExam;

  const LevelNodeCompleted({super.key, required this.stars, this.isExam = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset(
          isExam ? 'assets/images/Exam Completed Level.svg' : 'assets/images/FinishedLevel.svg',
          width: 72,
          height: 72,
        ),
        // Floating Stars Arc
        if (!isExam)
          Positioned(
            top: -24,
            child: _buildStarsArc(),
          ),
      ],
    );
  }

  // Draw 3 stars in a slight arc
  Widget _buildStarsArc() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left Star (rotated, lower)
        Transform.rotate(
          angle: -0.25,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(
              Icons.star_rounded,
              color: stars >= 1 ? const Color(0xFFFFD56B) : Colors.black.withValues(alpha: 0.25),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 2),
        // Middle Star (centered, higher, larger)
        Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: Icon(
            Icons.star_rounded,
            color: stars >= 2 ? const Color(0xFFFFD56B) : Colors.black.withValues(alpha: 0.25),
            size: 26,
          ),
        ),
        const SizedBox(width: 2),
        // Right Star (rotated, lower)
        Transform.rotate(
          angle: 0.25,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(
              Icons.star_rounded,
              color: stars >= 3 ? const Color(0xFFFFD56B) : Colors.black.withValues(alpha: 0.25),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// 2. Active Node (Yellow circle with white star inside, white "Level 3" tooltip bubble above)
class LevelNodeActive extends StatelessWidget {
  final int levelNumber;
  final bool isExam;

  const LevelNodeActive({super.key, required this.levelNumber, this.isExam = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset(
          isExam ? 'assets/images/Exam Locked Level.svg' : 'assets/images/CurrentLevel.svg',
          width: 72,
          height: 72,
        ),
        // Tooltip speech bubble above
        Positioned(
          top: -46,
          child: _buildTooltipBubble(),
        ),
      ],
    );
  }

  Widget _buildTooltipBubble() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The bubble container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            isExam ? "Exam" : "Level $levelNumber",
            style: GoogleFonts.nunito(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        // Triangle tail pointing down
        CustomPaint(
          size: const Size(12, 6),
          painter: TrianglePainter(),
        ),
      ],
    );
  }
}

// Draws the tail pointing down on speech bubble
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Locked Node (Gray Circle, padlock inside)
class LevelNodeLocked extends StatelessWidget {
  final bool isExam;

  const LevelNodeLocked({super.key, this.isExam = false});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      isExam ? 'assets/images/Exam Locked Level.svg' : 'assets/images/Locked Level.svg',
      width: 72,
      height: 72,
    );
  }
}

// 4. Crown Node (Silver/Gray Circle, crown inside)
class LevelNodeCrown extends StatelessWidget {
  const LevelNodeCrown({super.key});

  @override
  Widget build(BuildContext context) {
    return Duo3dCircleButton(
      faceColor: const Color(0xFFCCCCCC),
      shadowColor: const Color(0xFFB0B0B0),
      onPressed: null,
      size: 72,
      child: const Icon(
        Icons.workspace_premium_rounded, // Best fit for premium crown representation
        color: Colors.white,
        size: 36,
      ),
    );
  }
}
