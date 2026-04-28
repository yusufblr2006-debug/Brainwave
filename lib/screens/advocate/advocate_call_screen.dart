import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/speech_service.dart';
import '../../services/websocket_service.dart';

class AdvocateCallScreen extends StatefulWidget {
  const AdvocateCallScreen({super.key});
  @override
  State<AdvocateCallScreen> createState() => _AdvocateCallScreenState();
}

class _AdvocateCallScreenState extends State<AdvocateCallScreen> with TickerProviderStateMixin {
  final _speech = SpeechService();
  final _ws = WebSocketService();
  String _officerText = '';
  String _displayAiText = '';
  bool _active = true;
  bool _listening = false;
  bool _speaking = false;
  int _seconds = 0;
  Timer? _timer;
  StreamSubscription<String>? _wsSub;
  late AnimationController _radarCtrl;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _startProxy();
  }

  Future<void> _startProxy() async {
    await _ws.connect('demo-user');
    _wsSub = _ws.stream.listen((response) {
      if (!_active || !mounted) return;
      setState(() { _speaking = true; _displayAiText = ''; });
      _streamAiText(response);
    });
    _listenCycle();
  }

  Future<void> _streamAiText(String text) async {
    for (int i = 0; i <= text.length; i++) {
      if (!_active || !mounted) return;
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _displayAiText = text.substring(0, i));
    }
    // After text fully shown, speak it
    await _speech.speak(text);
    if (!_active || !mounted) return;
    setState(() => _speaking = false);
    _listenCycle();
  }

  void _listenCycle() {
    if (!_active || !mounted) return;
    setState(() { _listening = true; _officerText = ''; });
    _speech.startListening(
      onResult: (p) { if (mounted) setState(() => _officerText = p); },
      onComplete: (f) {
        if (!_active || !mounted) return;
        setState(() { _officerText = f; _listening = false; });
        _ws.send(f);
      },
    );
  }

  void _endCall() {
    _active = false;
    _speech.dispose();
    _ws.dispose();
    _wsSub?.cancel();
    _timer?.cancel();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _timer?.cancel();
    _active = false;
    _speech.dispose();
    _ws.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  String get _timeStr {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(50)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger))
                    .animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 600.ms).fadeOut(duration: 600.ms),
                const SizedBox(width: 10),
                Text('LIVE · $_timeStr', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
              ]),
            ).animate().fadeIn(),

            const Spacer(),

            // Radar
            SizedBox(
              width: 220, height: 220,
              child: AnimatedBuilder(
                animation: _radarCtrl,
                builder: (_, __) => CustomPaint(painter: _RadarPainter(_radarCtrl.value, _listening, _speaking)),
              ),
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 24),
            Text('Digital Advocate Active', style: AppTextStyles.displaySmall.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              _speaking ? 'AI is speaking to the officer...' : _listening ? 'AI is listening...' : 'Processing...',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60),
            ),

            const Spacer(),

            // Officer transcript
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FrostedGlassPanel(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Officer said:', style: AppTextStyles.bodySmall.copyWith(color: Colors.black45)),
                    const SizedBox(height: 4),
                    Text(_officerText.isEmpty ? '"Where are you going tonight?"' : '"$_officerText"', style: AppTextStyles.bodyLarge.copyWith(height: 1.4)),
                  ]),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 12),

            // AI response (gold border)
            Padding(
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.smart_toy_outlined, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Text('AI Responding:', style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold)),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      _displayAiText.isEmpty ? '"I am exercising my right to remain silent under Article 20(3)..."' : '"$_displayAiText"',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, height: 1.4),
                    ),
                  ]),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

            const SizedBox(height: 32),

            // End call
            GestureDetector(
              onTap: _endCall,
              child: Container(
                margin: const EdgeInsets.only(bottom: 28),
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
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

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
        ..shader = LinearGradient(colors: [color, color.withValues(alpha: 0.05)]).createShader(Rect.fromCircle(center: center, radius: maxR))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius, paint);
    }
    canvas.drawCircle(center, 14, Paint()..color = speaking ? AppColors.gradGreen : (listening ? AppColors.danger : AppColors.gradBlue));
    canvas.drawCircle(center, 28, Paint()..color = (speaking ? AppColors.gradGreen : AppColors.gradBlue).withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}
