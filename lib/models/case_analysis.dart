class CaseAnalysis {
  final String caseSummary, caseCategory;
  final List<String> applicableIndianLaws, missingEvidence;
  final int riskScore;
  factory CaseAnalysis.fromJson(Map<String,dynamic> j) => CaseAnalysis(
    caseSummary: j['case_summary'],
    applicableIndianLaws: List<String>.from(j['applicable_indian_laws']),
    missingEvidence: List<String>.from(j['missing_evidence']),
    riskScore: j['risk_score'],
    caseCategory: j['case_category']);

  CaseAnalysis({required this.caseSummary, required this.applicableIndianLaws, required this.missingEvidence, required this.riskScore, required this.caseCategory});
}
