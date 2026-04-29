import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../widgets/neu_card.dart';
import '../services/api_service.dart';
import '../providers/app_provider.dart';
import '../models/chat_message.dart';

/// Rewritten Chat Screen using Reverse ListView to eliminate twitching.
/// Newest messages are stored at index 0.
class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> lawyer;
  final String sessionId;

  const ChatScreen({
    super.key,
    required this.lawyer,
    required this.sessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _introSent = false;

  @override
  void initState() {
    super.initState();
    _sendInitialContext();
  }

  Future<void> _sendInitialContext() async {
    if (_introSent) return;
    _introSent = true;
    final provider = context.read<AppProvider>();
    final caseContext = provider.caseAnalysis;
    final caseSummary = caseContext?.caseSummary ?? 'New client consultation';
    final caseCategory = caseContext?.caseCategory ?? 'General';
    final lawyerName = widget.lawyer['name'] as String;

    final intro = 'A client has been connected to you via JudisAI. '
        'Here is their case summary: $caseSummary. '
        'Category: $caseCategory. '
        'Please introduce yourself as $lawyerName and ask how you can help '
        'them today. Keep your tone professional and empathetic.';

    if (mounted) setState(() => _loading = true);
    try {
      final reply = await ApiService.sendChat(widget.sessionId, intro);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant',
            content: '',
            timestamp: DateTime.now(),
          ));
          _loading = false;
        });
        await _typeMessage(reply);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant',
            content: '',
            timestamp: DateTime.now(),
          ));
          _loading = false;
        });
        await _typeMessage('Hello! I am ${widget.lawyer['name']}, specialising in ${widget.lawyer['spec'] ?? 'legal matters'}. How can I assist you today?');
      }
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();
    if (mounted) {
      setState(() {
        _messages.add(
            ChatMessage(role: 'user', content: text, timestamp: DateTime.now()));
        _loading = true;
      });
      _scrollToBottom();
    }
    try {
      final reply = await ApiService.sendChat(widget.sessionId, text);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
              role: 'assistant', content: '', timestamp: DateTime.now()));
          _loading = false;
        });
        await _typeMessage(reply);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(e.toString().replaceAll('Exception:', '').trim(),
              style: const TextStyle(fontFamily: 'Inter')),
        ));
      }
    }
  }

  Future<void> _typeMessage(String fullText) async {
    String current = "";

    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 15));
      current += fullText[i];

      if (!mounted) return;
      setState(() {
        _messages.last.content = current;
      });

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lawyerName = widget.lawyer['name'] as String;
    final lawyerSpec = (widget.lawyer['spec'] ?? '') as String;
    final initials = lawyerName.length >= 2
        ? lawyerName.substring(0, 1) +
            (lawyerName.split(' ').length > 1
                ? lawyerName.split(' ').last.substring(0, 1)
                : '')
        : lawyerName.substring(0, 1);

    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0xFFB8D4E8),
                              blurRadius: 8,
                              offset: Offset(2, 2))
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.gradBlue,
                    child: Text(initials,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lawyerName,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.textDark)),
                        Text(lawyerSpec,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textMid)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('Online',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ).animate().fadeIn(duration: 400.ms),

              // ── Message list (REVERSE: TRUE) ──────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_loading && i == _messages.length) {
                      return _typingBubble(lawyerName);
                    }
                    
                    final msg = _messages[i];
                    
                    return msg.role == 'user'
                        ? _userBubble(msg.content)
                        : _lawyerBubble(msg.content, lawyerName);
                  },
                ),
              ),

              // ── Input bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: NeuCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.textDark),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textMid),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _loading ? null : _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bubble helpers ─────────────────────────────────────────────────────────

  Widget _userBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.gradBlue, AppColors.gradGreen]),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gradBlue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Text(text,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lawyerBubble(String text, String lawyerName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.cardTint,
            child: Text(
              lawyerName.substring(0, 1),
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gradBlue),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lawyerName,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMid)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(text,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textDark,
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, duration: 200.ms);
  }

  Widget _typingBubble(String lawyerName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.cardTint,
            child: Text(
              lawyerName.substring(0, 1),
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gradBlue),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _dot(0),
              const SizedBox(width: 4),
              _dot(150),
              const SizedBox(width: 4),
              _dot(300),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
          color: AppColors.gradBlue, shape: BoxShape.circle),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
            end: 0.5,
            duration: 400.ms,
            delay: Duration(milliseconds: delayMs));
  }
}
