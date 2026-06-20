import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/user_data_service.dart';

class ChatMessage {
  final String text;
  final bool isBot;

  ChatMessage({
    required this.text,
    required this.isBot,
  });
}

class HelpCenterView extends StatefulWidget {
  final VoidCallback onBack;

  const HelpCenterView({super.key, required this.onBack});

  @override
  State<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState extends State<HelpCenterView> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  int _userAvatarIndex = 0;

  final List<Map<String, dynamic>> _avatars = [
    {'svgPath': 'assets/images/Characters/Female1.svg', 'bgColor': const Color(0xFFFFD56B)},
    {'svgPath': 'assets/images/Characters/Female2.svg', 'bgColor': const Color(0xFF8F93EA)},
    {'svgPath': 'assets/images/Characters/Female3.svg', 'bgColor': const Color(0xFFFF8B8B)},
    {'svgPath': 'assets/images/Characters/Male1.svg', 'bgColor': const Color(0xFFFFC5A5)},
    {'svgPath': 'assets/images/Characters/Male2.svg', 'bgColor': const Color(0xFF7A9EFF)},
    {'svgPath': 'assets/images/Characters/Male3.svg', 'bgColor': const Color(0xFF8CEEAD)},
  ];

  final Map<String, String> _faqResponses = {
    "How do streaks work?": "Streaks track your consecutive daily coding practice! Log in and complete lessons daily to maintain your streak. Missing a day resets it to 0!",
    "How to adjust volume?": "To adjust sound, navigate to Settings -> Preference -> Sound volume, or use your device's hardware volume keys!",
    "Report a problem": "Encountered a bug? Send an email to support@codu.com with detailed information or screenshots of the issue. We'll fix it ASAP!",
  };

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
    // Initial bot greeting
    _messages.add(
      ChatMessage(
        text: "Hi there, got any questions?",
        isBot: true,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAvatar() async {
    final idx = await UserDataService().getAvatarIndex();
    if (mounted) {
      setState(() {
        _userAvatarIndex = idx;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isBot: false));
      _isTyping = true;
    });
    _scrollToBottom();

    // Determine response
    String botReply = "Thanks for reaching out! I'm Codu's help assistant. Since I am still learning, please check our FAQs above or contact our team directly at support@codu.com.";
    
    // Check if it's one of our FAQs (ignoring emoji prefix)
    for (var entry in _faqResponses.entries) {
      if (text.contains(entry.key)) {
        botReply = entry.value;
        break;
      }
    }

    // Simulate typing delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: botReply, isBot: true));
        });
        _scrollToBottom();
      }
    });
  }

  Widget _buildFAQButton({
    required String label,
    required String icon,
    required String questionText,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleSendMessage(questionText),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEAECEF),
          foregroundColor: AppColors.textDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final avatar = (_userAvatarIndex >= 0 && _userAvatarIndex < _avatars.length)
        ? _avatars[_userAvatarIndex]
        : _avatars[0];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.isBot) ...[
            // Bot Mascot avatar on the left
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF8F93EA),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/images/CoduExpression/codu hi.svg',
                width: 30,
                height: 30,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isBot ? const Color(0xFF8F93EA) : const Color(0xFFE2E4E8),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: msg.isBot ? Radius.zero : const Radius.circular(20),
                  bottomRight: msg.isBot ? const Radius.circular(20) : Radius.zero,
                ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.nunito(
                  color: msg.isBot ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          if (!msg.isBot) ...[
            const SizedBox(width: 8),
            // User Avatar on the right
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatar['bgColor'],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.2,
                  child: SvgPicture.asset(
                    avatar['svgPath'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF56CCF2), // Sky Blue background
      body: Stack(
        children: [
          // Background SVG pattern
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/codu_background_pattern_mobile_soft.svg',
              fit: BoxFit.cover,
            ),
          ),
          // 1. Fixed Header Mascot (Rendered first at the bottom layer)
          Positioned(
            top: statusBarHeight + 45,
            left: 12,
            child: SvgPicture.asset(
              'assets/images/CoduExpression/codu hi.svg',
              width: 210,
              height: 210,
            ),
          ),

          // 2. Fixed Speech Bubble (Rendered next in the bottom layer)
          Positioned(
            top: statusBarHeight + 50,
            left: 190,
            right: 16,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Text(
                    "Hi there! How can I help you today?",
                    style: GoogleFonts.nunito(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Left-pointing tail
                Positioned(
                  left: -5,
                  bottom: 24,
                  child: Transform.rotate(
                    angle: 3.14159 / 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scrollable List (Covers full screen, scrolls OVER the mascot and speech bubble)
          Positioned.fill(
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                // Spacer matching the header height
                SizedBox(height: 195 + statusBarHeight),

                // White Panel containing chat content
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    // Ensure panel has minimum height to allow scroll coverage of header
                    minHeight: MediaQuery.of(context).size.height - (60 + statusBarHeight),
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(48),
                      topRight: Radius.circular(48),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 90), // Bottom padding for input field
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Chat Messages
                      ..._messages.map((msg) => _buildMessageBubble(msg)),
                      
                      // Typing Indicator
                      if (_isTyping) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8F93EA),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  'assets/images/CoduExpression/codu hi.svg',
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8F93EA),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  "Codu is typing...",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Frequently Asked Questions
                      Center(
                        child: Text(
                          "Frequently Asked Questions",
                          style: GoogleFonts.nunito(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFAQButton(
                        label: "How do streaks work?",
                        icon: "🔥",
                        questionText: "How do streaks work?",
                      ),
                      _buildFAQButton(
                        label: "How to adjust volume?",
                        icon: "🔊",
                        questionText: "How to adjust volume?",
                      ),
                      _buildFAQButton(
                        label: "Report a problem",
                        icon: "🏳️",
                        questionText: "Report a problem",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Back Button (Pinned at the top layer)
          Positioned(
            top: statusBarHeight + 16,
            left: 16,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                onPressed: widget.onBack,
              ),
            ),
          ),

          // 5. Message Input Field (Pinned at the bottom layer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SafeArea(
                top: false,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAECEF),
                    borderRadius: BorderRadius.circular(27),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: GoogleFonts.nunito(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: "Type your question...",
                            hintStyle: GoogleFonts.nunito(
                              color: Colors.black.withValues(alpha: 0.25),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            _handleSendMessage(val);
                            _inputController.clear();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _handleSendMessage(_inputController.text);
                          _inputController.clear();
                        },
                      ),
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
}
