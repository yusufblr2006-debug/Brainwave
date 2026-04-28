import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently selected case ID (for detail view)
final selectedCaseIdProvider = StateProvider<String>((ref) => 'MN-23109');

/// Evidence checklist toggle state
final evidenceChecklistProvider = StateProvider<List<bool>>((ref) => [true, true, false, false, false]);
