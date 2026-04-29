import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/neu_card.dart';
import '../widgets/grad_button.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/ocr_result.dart';

// ── Data class ────────────────────────────────────────────────────────────────
class _PickedImage {
  final String name;
  final Uint8List bytes;
  const _PickedImage({required this.name, required this.bytes});
}

class EvidenceAnalyzerScreen extends StatefulWidget {
  const EvidenceAnalyzerScreen({super.key});
  @override
  State<EvidenceAnalyzerScreen> createState() => _EvidenceAnalyzerScreenState();
}

class _EvidenceAnalyzerScreenState extends State<EvidenceAnalyzerScreen> {
  // ── Image state (drives image UI only) ────────────────────────────────────
  final List<_PickedImage> _images = [];
  bool _imageLoading = false; // true while reading bytes from disk

  // ── Result state (separate ValueNotifier — image UI never rebuilds for this)
  final ValueNotifier<OcrResult?> _resultNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _analyzingNotifier = ValueNotifier(false);

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _resultNotifier.dispose();
    _analyzingNotifier.dispose();
    super.dispose();
  }

  void _showError(dynamic e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFFDC2626),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(e.toString().replaceAll('Exception:', '').trim()),
    ));
  }

  Future<void> _pickImages() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() => _imageLoading = true);
    final newImages = await Future.wait(picked.map((xf) async {
      final bytes = await xf.readAsBytes();
      return _PickedImage(name: xf.name, bytes: bytes);
    }));
    if (mounted) {
      setState(() {
        _images.addAll(newImages);
        _imageLoading = false;
        // Reset result when new images added
        _resultNotifier.value = null;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? xf = await _picker.pickImage(source: ImageSource.camera);
    if (xf == null) return;
    setState(() => _imageLoading = true);
    final bytes = await xf.readAsBytes();
    if (mounted) {
      setState(() {
        _images.add(_PickedImage(name: xf.name, bytes: bytes));
        _imageLoading = false;
        _resultNotifier.value = null;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) _resultNotifier.value = null;
    });
  }

  Future<void> _analyze() async {
    if (_images.isEmpty && !kMockMode) return;
    // Use ValueNotifier — only the result widget rebuilds, not image thumbnails
    _analyzingNotifier.value = true;
    _resultNotifier.value = null;
    try {
      final first = _images.isNotEmpty ? _images.first : null;
      final res = await ApiService.uploadOcr(
        first?.bytes ?? Uint8List(0),
        first?.name ?? 'image.jpg',
      );
      _resultNotifier.value = res;
    } catch (e) {
      _showError(e);
    } finally {
      _analyzingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
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
                        boxShadow: const [BoxShadow(color: Color(0xFFB8D4E8), blurRadius: 8, offset: Offset(2, 2))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.camera_alt, color: AppColors.gradGreen),
                  const SizedBox(width: 8),
                  Text('Evidence Analyzer', style: AppTextStyles.headlineMedium),
                ]),
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20, right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Upload zone OR thumbnails ─────────────────────────
                      if (_images.isEmpty && !_imageLoading)
                        NeuCard(
                          onTap: _pickImages,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.3), width: 2),
                            ),
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                              ),
                              const SizedBox(height: 16),
                              Text('Tap to upload evidence', style: AppTextStyles.labelMedium.copyWith(color: AppColors.gradBlue)),
                              const SizedBox(height: 4),
                              Text('Select multiple images & documents', style: AppTextStyles.bodySmall),
                            ]),
                          ),
                        ).animate().fadeIn()

                      else if (_imageLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )

                      else ...[
                        // ── Image thumbnail panel (stateful — rebuilds only for image changes)
                        NeuCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(
                                  '${_images.length} image${_images.length > 1 ? 's' : ''} selected',
                                  style: AppTextStyles.labelMedium,
                                ),
                                const Spacer(),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(50)),
                                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.add_photo_alternate, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Flexible(child: Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: _pickFromCamera,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.cardTint,
                                        borderRadius: BorderRadius.circular(50),
                                        border: Border.all(color: AppColors.gradBlue.withValues(alpha: 0.3)),
                                      ),
                                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.camera_alt, color: AppColors.gradBlue, size: 14),
                                        SizedBox(width: 4),
                                        Flexible(child: Text('Camera', style: TextStyle(color: AppColors.gradBlue, fontSize: 12, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              // Thumbnail row — RepaintBoundary isolates each thumb
                              SizedBox(
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _images.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                                  itemBuilder: (_, idx) {
                                    final img = _images[idx];
                                    return RepaintBoundary(
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.memory(
                                              img.bytes,
                                              width: 90,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              // gaplessPlayback prevents flash on rebuild
                                              gaplessPlayback: true,
                                            ),
                                          ),
                                          Positioned(
                                            top: -6, right: -6,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(idx),
                                              child: Container(
                                                width: 22, height: 22,
                                                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4, left: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                              child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Inter')),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── Analyze button ─────────────────────────────────
                        ValueListenableBuilder<bool>(
                          valueListenable: _analyzingNotifier,
                          builder: (_, analyzing, __) => GradButton(
                            text: 'Analyze Evidence',
                            onPressed: analyzing ? () {} : _analyze,
                            isLoading: analyzing,
                            icon: Icons.search,
                          ),
                        ),
                      ],

                      // ── Loading shimmer (result only — image is already shown)
                      ValueListenableBuilder<bool>(
                        valueListenable: _analyzingNotifier,
                        builder: (_, analyzing, __) {
                          if (!analyzing) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text('Extracting Legal Context...',
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gradBlue))
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .shimmer(color: AppColors.gradBlue.withValues(alpha: 0.3)),
                            ),
                          );
                        },
                      ),

                      // ── Result card (ValueNotifier — ONLY this widget rebuilds)
                      ValueListenableBuilder<OcrResult?>(
                        valueListenable: _resultNotifier,
                        builder: (_, result, __) {
                          if (result == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: NeuCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.warning_rounded, color: AppColors.danger, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Violations Found', style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger)),
                                  ]),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.cardTint)),
                                  ...(result.legalViolations).map((v) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(v, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark))),
                                    ]),
                                  )),
                                  const SizedBox(height: 20),
                                  Row(children: [
                                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Actionable Next Steps', style: AppTextStyles.labelLarge.copyWith(color: AppColors.success)),
                                  ]),
                                  const SizedBox(height: 12),
                                  ...(result.recommendedActions).asMap().entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Container(
                                        width: 20, height: 20,
                                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(e.value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark))),
                                    ]),
                                  )),
                                  const SizedBox(height: 20),
                                  GradButton(
                                    text: 'Draft Complaint Letter',
                                    onPressed: () => context.push('/complaint-letter'),
                                    icon: Icons.edit_document,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(),
                          );
                        },
                      ),

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
}
