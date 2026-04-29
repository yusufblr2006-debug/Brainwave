import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/neu_card.dart';
import '../widgets/pill_input.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/app_provider.dart';
import '../models/chat_message.dart';

// ── Message model ────────────────────────────────────────────────────────────
enum _Role { user, ai }

class _Msg {
  final _Role role;
  String content;
  _Msg(this.role, this.content);
}

// ── Chat phases ───────────────────────────────────────────────────────────────
enum _Phase { setup, chatting, generating, report }

class AiEngineScreen extends StatefulWidget {
  const AiEngineScreen({super.key});
  @override
  State<AiEngineScreen> createState() => _AiEngineScreenState();
}

class _AiEngineScreenState extends State<AiEngineScreen> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _ctrl = TextEditingController();
  final _chatScroll = ScrollController();

  // ── State ──────────────────────────────────────────────────────────────────
  _Phase _phase = _Phase.setup;
  final List<_Msg> _messages = [];
  bool _loading = false;
  String _initialQuery = ''; // Track query from route params if any

  // ── STT ────────────────────────────────────────────────────────────────────
  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _sttListening = false; // local flag — avoids setState from onStatus
  String _locale = 'en_IN';

  static const Map<String, String> _langs = {
    'English': 'en_IN',
    'Hindi': 'hi_IN',
    'Kannada': 'kn_IN',
    'Tamil': 'ta_IN',
    'Telugu': 'te_IN',
  };

  @override
  void initState() {
    super.initState();
    _initStt();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final provider = context.read<AppProvider>();
    if (provider.sessionId.isEmpty) return;
    try {
      final history = await ApiService.getConversation(provider.sessionId);
      if (mounted && history.isNotEmpty) {
        setState(() {
          _messages.clear();
          for (var m in history) {
            _messages.add(_Msg(
              m['role'] == 'assistant' ? _Role.ai : _Role.user,
              m['content'] ?? '',
            ));
          }
          _phase = _Phase.chatting;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('History load failed: $e');
    }
  }

  // ── STT init with permission_handler ─────────────────────────────────────
  Future<void> _initStt() async {
    // Request microphone permission before initializing STT
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Microphone permission denied. Please enable it in Android Settings.',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: AppColors.danger,
        ));
      }
      return;
    }
    // Permission granted — initialize STT
    _sttAvailable = await _stt.initialize(
      // onError/onStatus ONLY update the local flag, never call setState
      // (prevents whole-page rebuilds while chat is visible)
      onError: (_) {
        _sttListening = false;
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _sttListening = false;
              });
            }
          });
        }
      },
      onStatus: (s) {
        final listening = s == 'listening';
        if (listening != _sttListening && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _sttListening = listening);
          });
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_sttAvailable || _stt.isListening) return;
    setState(() => _sttListening = true);
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) {
        _ctrl.text = r.recognizedWords;
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
      localeId: _locale,
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    setState(() => _sttListening = false);
  }

  // ── Scroll ─────────────────────────────────────────────────────────────────
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  // ── Send message ───────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    final provider = context.read<AppProvider>();
    _ctrl.clear();

    setState(() {
      if (_phase == _Phase.setup) {
        _phase = _Phase.chatting;
        _initialQuery = text;
      }
      _messages.add(_Msg(_Role.user, text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await ApiService.sendChat(provider.sessionId, text);
      provider.addMessage(ChatMessage(role: 'user', content: text, timestamp: DateTime.now()));
      provider.addMessage(ChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now()));
      if (mounted) {
        setState(() {
          _messages.add(_Msg(_Role.ai, reply));
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Msg(_Role.ai, 'Error: ${e.toString().replaceAll('Exception:', '').trim()}'));
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  // ── End chat → generate report ────────────────────────────────────────────
  Future<void> _endChat() async {
    if (_messages.isEmpty || _loading) return;
    setState(() {
      _phase = _Phase.generating;
      _loading = true;
    });
    _scrollToBottom();

    // Ask AI to summarize the case
    const prompt =
        'Based on our conversation, please provide a structured case summary with: '
        '1) Case Summary, 2) Legal Insights, 3) Risk Score (LOW/MEDIUM/HIGH), '
        '4) Suggested Actions. Format clearly.';
    try {
      final provider = context.read<AppProvider>();
      final reply = await ApiService.sendChat(provider.sessionId, prompt);
      if (mounted) {
        setState(() {
          _messages.add(_Msg(_Role.ai, reply));
          _loading = false;
          _phase = _Phase.report;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _phase = _Phase.chatting; // revert on failure
        });
      }
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  void _reset() {
    setState(() {
      _messages.clear();
      _phase = _Phase.setup;
      _loading = false;
      _ctrl.clear();
      _initialQuery = '';
    });
  }

  // ── PDF report ─────────────────────────────────────────────────────────────
  Future<void> _generatePdf() async {
    final doc = pw.Document();
    
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('JudisAI — Case Analysis Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Text('CONFIDENTIAL', style: pw.TextStyle(fontSize: 10, color: PdfColors.red800)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        
        _pdfSection('1. CASE SUMMARY', 'The client is seeking legal guidance regarding a potential property dispute involving unauthorized construction and encroachment on ancestral land.'),
        
        _pdfSection('2. RELEVANT LAWS (INDIAN)', '• IPC Section 441: Criminal Trespass\n• IPC Section 425: Mischief\n• Indian Registration Act 1908\n• Specific Relief Act 1963'),
        
        _pdfSection('3. RISK SCORE', 'MEDIUM RISK (65%)\nThe complexity of land records and the presence of unauthorized construction pose a moderate challenge to immediate resolution.'),
        
        _pdfSection('4. STRATEGIC ACTION PLAN', '1. Issue a formal legal notice to the encroaching party.\n2. File a complaint with the local Municipal Corporation.\n3. Apply for a temporary injunction (Stay Order) in the Civil Court.\n4. Lodge an FIR at the local Police Station under IPC 441.'),
        
        _pdfSection('5. EVIDENCE REQUIRED', '• Registered Sale Deed / Title Deeds\n• Encumbrance Certificate (EC) for last 30 years\n• Recent Survey Map and Possession Certificate\n• Photographs and Video evidence of encroachment'),
        
        _pdfSection('6. ESTIMATED TIMELINE', '• Legal Notice: 1 week\n• Injunction Order: 2-4 weeks\n• Civil Suit Resolution: 12-24 months'),
        
        _pdfSection('7. OUTCOME PREDICTION', 'FAVORABLE (75% PROBABILITY)\nGiven the clear title deeds and documented unauthorized construction, there is a high likelihood of obtaining a stay order and eventual restoration of boundaries.'),
        
        pw.Spacer(),
        pw.Divider(),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Generated by JudisAI Legal Engine on ${DateTime.now().toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'JudisAI_Legal_Report.pdf');
  }

  pw.Widget _pdfSection(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 4),
          pw.Text(content, style: const pw.TextStyle(fontSize: 11, lineSpacing: 4)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _chatScroll.dispose();
    _stt.cancel();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final inChat = _phase != _Phase.setup;
    final isReport = _phase == _Phase.report;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(2, 2))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.auto_awesome, color: AppColors.gradBlue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('AI Legal Engine',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Inter')),
                  ),
                  if (_phase == _Phase.chatting)
                    GestureDetector(
                      onTap: _endChat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFFF97316)]),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.summarize, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('End Chat', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  if (isReport)
                    GestureDetector(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardTint,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.refresh, color: AppColors.gradBlue, size: 14),
                          SizedBox(width: 4),
                          Text('New Case', style: TextStyle(color: AppColors.gradBlue, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                ]),
              ),

              // ── Main Content Area ──────────────────────────────────────────
              if (!inChat)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: NeuCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Language:', style: AppTextStyles.labelMedium),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _langs.keys.map((lang) {
                              final selected = _locale == _langs[lang];
                              return GestureDetector(
                                onTap: () => setState(() => _locale = _langs[lang]!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: selected ? const LinearGradient(colors: [AppColors.gradBlue, AppColors.gradGreen]) : null,
                                    color: selected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(lang,
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: selected ? Colors.white : AppColors.gradBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Text('Quick Templates:', style: AppTextStyles.labelMedium),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: DummyData.aiTemplates.map((t) => GestureDetector(
                              onTap: () => setState(() => _ctrl.text = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardTint,
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.2)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.bolt, color: AppColors.gradBlue, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(t, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gradBlue))),
                                ]),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: _chatScroll,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    itemCount: _messages.isEmpty ? 1 : _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_messages.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: Text(
                              'Describe your legal situation below\nand tap Send to begin.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMid),
                            ),
                          ),
                        );
                      }
                      if (_loading && i == _messages.length) return _TypingBubble();
                      
                      final msg = _messages[i];
                      final isUser = msg.role == _Role.user;
                      final isReportCard = isReport && i == _messages.length - 1 && !isUser;
                      
                      if (isReportCard) {
                        return _ReportCard(
                          content: msg.content,
                          onDownload: _generatePdf,
                          onNewCase: _reset,
                        );
                      }
                      return _ChatBubble(isUser: isUser, text: msg.content);
                    },
                  ),
                ),

              // ── Input Bar ──────────────────────────────────────────────────
              if (!isReport)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: _InputBar(
                    ctrl: _ctrl,
                    loading: _loading,
                    sttListening: _sttListening,
                    sttAvailable: _sttAvailable,
                    onSend: _send,
                    onMic: _sttListening ? _stopListening : _startListening,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Extracted widgets (no setState coupling to parent) ────────────────────────

class _ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;
  const _ChatBubble({required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.cardTint,
              child: Icon(Icons.auto_awesome, size: 14, color: AppColors.gradBlue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(text,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: isUser ? Colors.white : AppColors.textDark,
                        height: 1.5)),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.cardTint,
          child: Icon(Icons.auto_awesome, size: 14, color: AppColors.gradBlue),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Text('AI is thinking...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMid)),
        ),
      ]).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(color: AppColors.gradBlue.withValues(alpha: 0.3)),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String content;
  final VoidCallback onDownload;
  final VoidCallback onNewCase;
  const _ReportCard({required this.content, required this.onDownload, required this.onNewCase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: const Icon(Icons.summarize, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Case Report', style: AppTextStyles.labelLarge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(50)),
                child: Text('COMPLETE', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardTint),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Text(content,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textDark, height: 1.6)),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download PDF', overflow: TextOverflow.ellipsis),
                  onPressed: onDownload,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onNewCase,
                  child: const Text('Start New Case', overflow: TextOverflow.ellipsis),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Text('Recommended Lawyers:', style: AppTextStyles.labelMedium),
            const SizedBox(height: 12),
            ...DummyData.lawyers.take(3).map((l) => _lawyerMiniCard(context, l)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _lawyerMiniCard(BuildContext context, Map<String, dynamic> l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.gradBlue.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: AppColors.gradBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l['name'], style: AppTextStyles.labelMedium),
                Text('${l['spec']} · ${l['experience']}', style: AppTextStyles.bodySmall),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.gold, size: 14),
                    const SizedBox(width: 4),
                    Text('${l['rating']} · ₹${l['price']}', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Consultation booked with ${l['name']}!')),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 12),
              minimumSize: const Size(60, 32),
            ),
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final bool sttListening;
  final bool sttAvailable;
  final VoidCallback onSend;
  final VoidCallback onMic;
  const _InputBar({
    required this.ctrl,
    required this.loading,
    required this.sttListening,
    required this.sttAvailable,
    required this.onSend,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mic button
            GestureDetector(
              onTap: sttAvailable ? onMic : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: sttListening
                      ? const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFF97316)])
                      : const LinearGradient(
                          colors: [AppColors.gradBlue, AppColors.gradGreen]),
                  shape: BoxShape.circle,
                ),
                child: Icon(sttListening ? Icons.stop_circle : Icons.mic,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // Text input
            Expanded(
              child: Container(
                width: double.infinity,
                child: PillInput(
                  hintText: 'Type your message...',
                  controller: ctrl,
                  minLines: 1,
                  maxLines: 5,
                  prefixIcon: null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: loading ? null : onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
    }
  }
