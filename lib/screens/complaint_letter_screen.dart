import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../widgets/neu_card.dart';
import '../widgets/grad_button.dart';

class ComplaintLetterScreen extends StatefulWidget {
  const ComplaintLetterScreen({super.key});

  @override
  State<ComplaintLetterScreen> createState() => _ComplaintLetterScreenState();
}

class _ComplaintLetterScreenState extends State<ComplaintLetterScreen> {
  bool _generating = true;
  String _letter = '';

  @override
  void initState() {
    super.initState();
    _generateLetter();
  }

  Future<void> _generateLetter() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _generating = false;
      _letter = '''
RAKESH SHARMA
123, Jubilee Hills, Hyderabad, Telangana - 500033
Contact: +91 98765 43210
Date: April 29, 2026

TO,
THE STATION HOUSE OFFICER,
Jubilee Hills Police Station,
Hyderabad, Telangana.

SUBJECT: FORMAL COMPLAINT REGARDING PROPERTY ENCROACHMENT AND UNAUTHORIZED CONSTRUCTION ON SURVEY NO. 445/A.

RESPECTED SIR/MADAM,

I, Rakesh Sharma, son of Late Sh. Suresh Sharma, resident of the above-mentioned address, hereby submit this formal complaint regarding the illegal encroachment on my ancestral property located at Survey No. 445/A, Jubilee Hills.

On the morning of April 25, 2026, I observed that certain unknown individuals, allegedly acting on behalf of one Mr. Vinay Gupta, have commenced unauthorized construction on the northern boundary of my property. Despite my repeated requests to halt the work and produce legal permits, they continued the construction in a high-handed manner.

LEGAL PROVISIONS INVOLVED:
1. Section 441 of the Indian Penal Code (IPC): Criminal Trespass.
2. Section 425 of the IPC: Mischief causing damage to property.
3. Section 145 of the CrPC: Dispute concerning land or water likely to cause breach of peace.

PRAYER:
I request your good office to:
a) Immediately register an FIR against Mr. Vinay Gupta and his associates.
b) Direct the concerned individuals to stop any further unauthorized construction.
c) Provide necessary protection to prevent any further encroachment.

I have attached copies of my sale deed and recent survey maps for your reference.

SINCERELY,

(SIGNATURE)
RAKESH SHARMA
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Legal Complaint', style: AppTextStyles.headlineMedium),
                ]),
              ),

              Expanded(
                child: _generating
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: AppColors.gradBlue),
                            const SizedBox(height: 16),
                            Text('Drafting formal letter...', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 20, right: 20, top: 20,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                        ),
                        child: Column(
                          children: [
                            NeuCard(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _letter,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  height: 1.6,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ).animate().fadeIn(duration: 600.ms),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: GradButton(
                                    text: 'Download PDF',
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('PDF downloaded successfully!')),
                                      );
                                    },
                                    icon: Icons.download,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Letter copied to clipboard!')),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                      side: const BorderSide(color: AppColors.gradBlue),
                                    ),
                                    child: const Text('Copy Text', style: TextStyle(color: AppColors.gradBlue, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 300.ms),
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
