import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class AdvocateCallScreen extends StatefulWidget {
  const AdvocateCallScreen({super.key});
  @override
  State<AdvocateCallScreen> createState() => _AdvocateCallScreenState();
}

class _AdvocateCallScreenState extends State<AdvocateCallScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  WebSocketChannel? _ws;

  bool _isLive = false;
  bool _isSpeaking = false;
  bool _sttAvailable = false;
  bool _isFirstMessage = true;

  String _transcript = 'Speak now...';
  String _aiResponse = 'Awaiting response...';
  String _status = 'READY';
  int _secs = 0;
  Timer? _timer;

  // Conversation history for context
  final List<Map<String, String>> _history = [];
  
  late AnimationController _radarCtrl;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _init();
  }

  Future<void> _init() async {
    // TTS — sound natural, not robotic
    await _tts.setLanguage('en-IN');
    await _tts.setPitch(1.0);        // natural pitch
    await _tts.setSpeechRate(0.52);  // natural pace
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    // STT
    _sttAvailable = await _stt.initialize(
      onError: (e) { if (mounted) setState(() => _status = 'MIC ERROR'); },
      onStatus: (s) {
        // When STT stops naturally (user finished) → don't restart if AI is speaking
        if (s == 'done' && _isLive && !_isSpeaking) {
          Future.delayed(const Duration(milliseconds: 200), _startListening);
        }
      },
    );
    
    // Auto-activate when screen opens
    _activate();
  }

  Future<void> _activate() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';
    _history.clear();
    _isFirstMessage = true;

    _ws = WebSocketChannel.connect(
      Uri.parse('$WS_URL/ws/advocate/$userId'));

    _ws!.stream.listen((msg) async {
      final text = msg.toString();
      _history.add({'role': 'ai', 'text': text});

      if (mounted) {
        setState(() {
          _status = 'SPEAKING';
          _isSpeaking = true;
        });
      }

      // Stop STT immediately when AI starts speaking
      await _stt.stop();
      
      // Start typing effect
      await _typeAiResponse(text);
      
      await _tts.speak(text);

      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _status = 'LISTENING';
        });
      }

      // Resume listening after AI finishes
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isLive && mounted) _startListening();
    },
    onError: (_) {
      if (mounted) {
        setState(() => _status = 'DISCONNECTED');
      }
    },
    onDone: () {
      if (_isLive && mounted) {
        setState(() => _status = 'ENDED');
      }
    });

    if (mounted) {
      setState(() {
        _isLive = true;
        _status = 'LISTENING';
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _secs++);
      }
    });
    _startListening();
  }

  Future<void> _typeAiResponse(String fullText) async {
    String current = "";
    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 15));
      current += fullText[i];
      if (!mounted) return;
      setState(() {
        _aiResponse = current;
      });
    }
  }

  Future<void> _startListening() async {
    if (!_sttAvailable || !_isLive || _isSpeaking) return;
    if (_stt.isListening) return;

    if (mounted) setState(() => _status = 'LISTENING');

    await _stt.listen(
      onResult: (r) {
        if (!mounted) return;
        final words = r.recognizedWords;
        if (words.isNotEmpty) {
          setState(() => _transcript = '"$words"');
        }
        if (r.finalResult && words.isNotEmpty) {
          _history.add({'role': 'user', 'text': words});
          setState(() => _status = 'PROCESSING');

          _ws?.sink.add(jsonEncode({
            'speaker': 'police',
            'text': words,
            'is_continuation': !_isFirstMessage,
            'history': _history.take(10).toList(),
          }));
          _isFirstMessage = false;
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
      localeId: 'en_IN',
    );
  }

  void _endCall() {
    _stt.stop();
    _tts.stop();
    _ws?.sink.close();
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isLive = false; _secs = 0;
        _status = 'READY'; _isFirstMessage = true;
        _history.clear();
      });
    }
    context.pop();
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _endCall();
    super.dispose();
  }

  String get _timeStr {
    final m = (_secs ~/ 60).toString().padLeft(2, '0');
    final s = (_secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildLiveBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .fadeOut(duration: 600.ms),
        const SizedBox(width: 10),
        Text(
          _isLive ? 'LIVE · $_timeStr' : 'CONNECTING...',
          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
        ),
      ]),
    ).animate().fadeIn();
  }

  Widget _buildRadar() {
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: AnimatedBuilder(
          animation: _radarCtrl,
          builder: (_, __) => CustomPaint(
            painter: _RadarPainter(
              _radarCtrl.value,
              _status == 'LISTENING',
              _status == 'SPEAKING',
            ),
          ),
        ),
      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildTitleStatus() {
    return Column(
      children: [
        Text('Digital Advocate Active', style: AppTextStyles.displaySmall.copyWith(color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gradBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(_status, style: AppTextStyles.labelMedium.copyWith(color: AppColors.gradBlue, letterSpacing: 1.2)),
        ),
      ],
    );
  }

  Widget _buildOfficerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FrostedGlassPanel(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Officer said:', style: AppTextStyles.bodySmall.copyWith(color: Colors.black45)),
                const SizedBox(height: 4),
                Text(_transcript, style: AppTextStyles.bodyLarge.copyWith(height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildAiCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.smart_toy_outlined, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Text('AI Responding:', style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold)),
              ]),
              const SizedBox(height: 6),
              Text(_aiResponse, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, height: 1.4)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildEndButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.call_end, color: Colors.white),
          const SizedBox(width: 10),
          Text('END CALL', style: AppTextStyles.buttonText.copyWith(letterSpacing: 1)),
        ]),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 20),
          // LIVE timer — fixed height
          _buildLiveBar(),
          // Radar — flexible, takes remaining space
          Expanded(child: _buildRadar()),
          // Title + status — fixed
          _buildTitleStatus(),
          const SizedBox(height: 12),
          // Cards — fixed height with internal scroll
          SizedBox(height: 100, child: _buildOfficerCard()),
          const SizedBox(height: 12),
          SizedBox(height: 120, child: SingleChildScrollView(child: _buildAiCard())),
          const SizedBox(height: 32),
          // End button
          _buildEndButton(),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ── Radar painter (unchanged UI) ─────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final double progress;
  final bool listening, speaking;
  _RadarPainter(this.progress, this.listening, this.speaking);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final color = listening ? AppColors.danger : AppColors.gradGreen;
    for (int i = 0; i < 3; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final radius = maxR * phase;
      final paint = Paint()
        ..shader = LinearGradient(colors: [color, color.withValues(alpha: 0.05)])
            .createShader(Rect.fromCircle(center: center, radius: maxR))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius, paint);
    }
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = speaking
            ? AppColors.gradGreen
            : (listening ? AppColors.danger : AppColors.gradBlue),
    );
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..color = (speaking ? AppColors.gradGreen : AppColors.gradBlue)
            .withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}
