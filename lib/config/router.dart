import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/emergency_screen.dart';
import '../screens/rights_detail_screen.dart';
import '../screens/ai_engine_screen.dart';
import '../screens/evidence_analyzer_screen.dart';
import '../screens/know_rights_screen.dart';
import '../screens/lawyer_marketplace_screen.dart';
import '../screens/advocate_call_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/case_detail_screen.dart';
import '../screens/lawyer_profile_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/lawyer_chat_screen.dart';
import '../screens/complaint_letter_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(path: '/home', builder: (_, __) => const CitizenHomeScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(
      path: '/case-detail',
      builder: (_, s) => CaseDetailScreen(caseData: s.extra as Map),
    ),
    GoRoute(path: '/emergency', builder: (_, __) => const EmergencyScreen()),
    GoRoute(
      path: '/rights-detail/:id',
      builder: (_, s) =>
          RightsDetailScreen(id: s.pathParameters['id']!),
    ),
    GoRoute(path: '/ai-engine', builder: (_, __) => const AiEngineScreen()),
    GoRoute(
        path: '/evidence',
        builder: (_, __) => const EvidenceAnalyzerScreen()),
    GoRoute(
        path: '/know-rights', builder: (_, __) => const KnowRightsScreen()),
    GoRoute(
        path: '/marketplace',
        builder: (_, __) => const LawyerMarketplaceScreen()),
    GoRoute(
      path: '/lawyer-profile',
      builder: (_, s) =>
          LawyerProfileScreen(lawyer: s.extra as Map),
    ),
    GoRoute(
      path: '/payment',
      builder: (_, s) => PaymentScreen(lawyer: s.extra as Map),
    ),
    GoRoute(
        path: '/advocate-call',
        builder: (_, __) => const AdvocateCallScreen()),
    GoRoute(
        path: '/complaint-letter',
        builder: (_, __) => const ComplaintLetterScreen()),
    GoRoute(
      path: '/lawyer-chat',
      builder: (_, s) {
        final args = s.extra as Map<String, dynamic>;
        return LawyerChatScreen(
          lawyer: args['lawyer'] as Map<String, dynamic>,
          sessionId: args['sessionId'] as String,
        );
      },
    ),
  ],
);
