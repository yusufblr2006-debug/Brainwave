import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/grad_button.dart';

class VoiceFirScreen extends StatefulWidget {
  const VoiceFirScreen({super.key});
  @override
  State<VoiceFirScreen> createState() => _VoiceFirScreenState();
}

class _VoiceFirScreenState extends State<VoiceFirScreen> {
  int _selectedLang = 2; // English default
  bool _recording = false;
  bool _processed = false;
  String _transcript = '';
  final _langs = ['Hindi', 'Kannada', 'English'];

  Future<void> _toggleRecording() async {
    if (_recording) {
      setState(() { _recording = false; });
      // Simulate processing
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processed = true);
    } else {
      setState(() { _recording = true; _processed = false; _transcript = ''; });
      // Simulate live transcript
      for (final chunk in [
        'I was stopped by a police officer ',
        'near MG Road at approximately 9pm. ',
        'He asked me to show my ID ',
        'without any reason or warrant...',
      ]) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!_recording || !mounted) break;
        setState(() => _transcript += chunk);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  GestureDetector(onTap: () => context.pop(), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(2, 2))]), child: const Icon(Icons.arrow_back_ios_new, size: 16))),
                  const SizedBox(width: 12),
                  const Icon(Icons.mic, color: Color(0xFF9333EA)),
                  const SizedBox(width: 8),
                  Text('Zero-FIR Voice Report', style: AppTextStyles.headlineMedium),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Language chips
                      Row(
                        children: _langs.asMap().entries.map((e) {
                          final active = e.key == _selectedLang;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedLang = e.key),
                              child: Container(
                                margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: active ? AppColors.primaryGradient : null,
                                  color: active ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: active ? null : const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 4, offset: Offset(2, 2))],
                                ),
                                alignment: Alignment.center,
                                child: Text(e.value, style: AppTextStyles.labelMedium.copyWith(color: active ? Colors.white : AppColors.textMid)),
                              ),
                            ),
                          );
                        }).toList(),
                      ).animate().fadeIn(),

                      const SizedBox(height: 40),

                      // Mic button
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: _recording ? AppColors.danger.withValues(alpha: 0.4) : const Color(0xFFB8D4E8), blurRadius: _recording ? 24 : 12, offset: const Offset(0, 4)),
                              const BoxShadow(color: Colors.white, blurRadius: 8, offset: Offset(-4, -4)),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: _recording ? AppColors.dangerGradient : AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic, color: Colors.white, size: 32),
                          ),
                        ),
                      ).animate(target: _recording ? 1 : 0).scaleXY(end: 1.1, duration: 600.ms),

                      const SizedBox(height: 16),
                      Text(
                        _recording ? 'Recording...' : (_processed ? 'Processing complete' : 'Tap to start recording'),
                        style: AppTextStyles.bodyMedium.copyWith(color: _recording ? AppColors.danger : AppColors.textMid),
                      ),

                      const SizedBox(height: 32),

                      // Live transcript
                      if (_transcript.isNotEmpty)
                        NeuCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [const Icon(Icons.edit_note, color: AppColors.gradBlue, size: 18), const SizedBox(width: 8), Text('Live Transcript', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMid))]),
                              const SizedBox(height: 12),
                              Text('"$_transcript"', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, fontStyle: FontStyle.italic, height: 1.5)),
                            ],
                          ),
                        ).animate().fadeIn(),

                      // FIR Draft
                      if (_processed) ...[
                        const SizedBox(height: 24),
                        NeuCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: Text('════════════════════════', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMid))),
                              const SizedBox(height: 8),
                              Center(child: Text('FIRST INFORMATION REPORT', style: AppTextStyles.labelLarge.copyWith(letterSpacing: 1))),
                              const SizedBox(height: 8),
                              Center(child: Text('════════════════════════', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMid))),
                              const SizedBox(height: 16),
                              _firRow('Date', '28/04/2025'),
                              _firRow('Police Station', 'MG Road, Bengaluru'),
                              _firRow('Complainant', 'Arjun Sharma'),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.cardTint)),
                              Text('Description of Incident:', style: AppTextStyles.labelMedium),
                              const SizedBox(height: 8),
                              Text(_transcript.isEmpty ? 'Awaiting transcript...' : _transcript, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark, height: 1.5)),
                              const SizedBox(height: 24),
                              Row(children: [
                                Expanded(child: GradButton(text: '↗ Share', onPressed: () {}, small: true, icon: Icons.share)),
                                const SizedBox(width: 12),
                                Expanded(child: GradButton(text: '⬇ Download', onPressed: () {}, small: true, icon: Icons.download)),
                              ]),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),
                      ],
                      const SizedBox(height: 40),
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

  Widget _firRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 120, child: Text('$label:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark))),
      ]),
    );
  }
}
