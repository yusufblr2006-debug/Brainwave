import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_select_screen.dart';
import '../screens/citizen/citizen_home_screen.dart';
import '../screens/citizen/emergency_screen.dart';
import '../screens/citizen/rights_detail_screen.dart';
import '../screens/citizen/ai_engine_screen.dart';
import '../screens/citizen/evidence_analyzer_screen.dart';
import '../screens/citizen/voice_fir_screen.dart';
import '../screens/citizen/know_rights_screen.dart';
import '../screens/citizen/lawyer_marketplace_screen.dart';
import '../screens/advocate/advocate_call_screen.dart';
import '../screens/lawyer/lawyer_home_screen.dart';
import '../screens/lawyer/case_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loggedIn = ref.read(isLoggedInProvider);
      final path = state.fullPath ?? '';
      final isAuthPage = path == '/login' || path == '/register' || path == '/splash';
      if (!loggedIn && !isAuthPage) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(path: '/home', builder: (_, __) => const CitizenHomeScreen()),
      GoRoute(path: '/emergency', builder: (_, __) => const EmergencyScreen()),
      GoRoute(path: '/rights-detail/:id', builder: (_, s) => RightsDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/ai-engine', builder: (_, __) => const AiEngineScreen()),
      GoRoute(path: '/evidence', builder: (_, __) => const EvidenceAnalyzerScreen()),
      GoRoute(path: '/voice-fir', builder: (_, __) => const VoiceFirScreen()),
      GoRoute(path: '/know-rights', builder: (_, __) => const KnowRightsScreen()),
      GoRoute(path: '/marketplace', builder: (_, __) => const LawyerMarketplaceScreen()),
      GoRoute(path: '/advocate-call', builder: (_, __) => const AdvocateCallScreen()),
      GoRoute(path: '/lawyer-home', builder: (_, __) => const LawyerHomeScreen()),
      GoRoute(path: '/case-detail/:id', builder: (_, s) => CaseDetailScreen(id: s.pathParameters['id']!)),
    ],
  );
});
