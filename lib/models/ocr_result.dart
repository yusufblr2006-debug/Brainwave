class OcrResult {
  final String extractedText;
  final List<String> legalViolations, recommendedActions;
  factory OcrResult.fromJson(Map<String,dynamic> j) => OcrResult(
    extractedText: j['extracted_text'],
    legalViolations: List<String>.from(j['legal_violations']),
    recommendedActions: List<String>.from(j['recommended_actions']));

  OcrResult({required this.extractedText, required this.legalViolations, required this.recommendedActions});
}
