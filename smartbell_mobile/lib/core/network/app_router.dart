import 'package:go_router/go_router.dart';

// Auth
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';

// Adherent
import '../../features/adherent/adherent_shell.dart';
import '../../features/adherent/home/screens/home_screen.dart';
import '../../features/adherent/training/screens/workout_session_screen.dart';
import '../../features/adherent/nutrition/screens/nutrition_screen.dart';
import '../../features/adherent/courses/screens/courses_screen.dart';
import '../../features/adherent/messaging/screens/chat_screen.dart';
import '../../features/adherent/loyalty/screens/loyalty_screen.dart';
import '../../features/adherent/profile_screen.dart';
import '../../features/adherent/coaches/screens/coaches_list_screen.dart';

// Coach
import '../../features/coach/coach_shell.dart';
import '../../features/coach/dashboard/screens/coach_dashboard_screen.dart';
import '../../features/coach/members/screens/members_list_screen.dart';
import '../../features/coach/validations/screens/coach_validations_screen.dart';
import '../../features/coach/planning/screens/planning_screen.dart';
import '../../features/coach/absences/screens/absence_screen.dart';
import '../../features/coach/profile_screen.dart';

// Legacy admin screens (kept for compatibility)
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_members_page.dart';
import '../../screens/admin/admin_coaches_page.dart';
import '../../screens/admin/admin_payments_page.dart';
import '../../screens/admin/admin_messages_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../../screens/admin/admin_complaints_page.dart';
import '../../screens/admin/admin_absences_page.dart';

// Coach messaging
import '../../features/coach/messaging/screens/coach_messages_screen.dart';

// Subscription
import '../../features/adherent/subscription/screens/member_subscription_screen.dart';

// Payments
import '../../features/adherent/payments/member_payments_screen.dart';

// Check-in
import '../../features/adherent/checkin/screens/checkin_history_screen.dart';
import '../../features/admin/qr_display_screen.dart';

// Machines / QR scanner
import '../../features/adherent/machines/qr_scanner_screen.dart';

// Events
import '../../features/adherent/events/screens/events_screen.dart';

// Notifications partagées
import '../../features/shared/notifications/notifications_screen.dart';

// Plaintes
import '../../features/adherent/complaints/screens/complaints_screen.dart';

// Coach ratings
import '../../features/coach/ratings/coach_ratings_screen.dart';


// Progress
import '../../features/adherent/progress/progress_screen.dart';

import '../../features/onboarding/onboarding_screen.dart';

GoRouter createAppRouter(AuthProvider auth, bool showOnboarding) => GoRouter(
  initialLocation: showOnboarding ? '/onboarding' : '/login',
  refreshListenable: auth,
  redirect: (context, state) {
    final status = auth.status;

    if (status == AuthStatus.unknown) return null; // still loading

    final loggedIn    = status == AuthStatus.authenticated;
    final path        = state.matchedLocation;
    final onAuth      = path == '/login' || path == '/register';
    final onOnboarding = path == '/onboarding';

    if (onOnboarding) return null;
    if (!loggedIn && !onAuth) return '/login';

    if (loggedIn && onAuth) {
      if (auth.isAdmin)  return '/admin';
      if (auth.isCoach)  return '/coach';
      return '/member';
    }

    // ── Role-based access guard ──────────────────────────────────────────────
    // Prevent a logged-in user from accessing routes meant for a different role.
    if (loggedIn) {
      final onAdmin  = path.startsWith('/admin');
      final onCoach  = path.startsWith('/coach');
      final onMember = path.startsWith('/member');

      if (onAdmin  && !auth.isAdmin)  return auth.isCoach ? '/coach'  : '/member';
      if (onCoach  && !auth.isCoach)  return auth.isAdmin ? '/admin'  : '/member';
      if (onMember && !auth.isMember) return auth.isAdmin ? '/admin'  : '/coach';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    // ── Auth ──
    GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // ── Adherent ──
    ShellRoute(
      builder: (_, __, child) => AdherentShell(child: child),
      routes: [
        GoRoute(path: '/member',           builder: (_, __) => const AdherentHomeScreen()),
        GoRoute(path: '/member/training',  builder: (_, __) => const WorkoutSessionScreen()),
        GoRoute(path: '/member/nutrition', builder: (_, __) => const NutritionScreen()),
        GoRoute(path: '/member/courses',   builder: (_, __) => const CoursesScreen()),
        GoRoute(path: '/member/chat',      builder: (_, __) => const ConversationsScreen()),
        GoRoute(path: '/member/loyalty',   builder: (_, __) => const LoyaltyScreen()),
        GoRoute(path: '/member/profile',   builder: (_, __) => const AdherentProfileScreen()),
        // Keep subscription & payments routes (from old shell)
        GoRoute(path: '/member/coaches',      builder: (_, __) => const AdherentCoachesScreen()),
        GoRoute(path: '/member/progress',     builder: (_, __) => const ProgressScreen()),
        GoRoute(path: '/member/subscription',    builder: (_, __) => const MemberSubscriptionScreen()),
        GoRoute(path: '/member/payments',         builder: (_, __) => const MemberPaymentsScreen()),
        GoRoute(path: '/member/checkin-history',  builder: (_, __) => const CheckinHistoryScreen()),
        GoRoute(path: '/member/events',           builder: (_, __) => const MemberEventsScreen()),
        GoRoute(path: '/member/notifications',    builder: (context, __) => NotificationsScreen(userId: auth.user?.id)),
        GoRoute(path: '/member/complaints',       builder: (_, __) => const ComplaintsScreen()),
      ],
    ),

    // ── QR Scanner (full-screen, no shell nav) ──
    GoRoute(path: '/member/scan', builder: (_, __) => const QrScannerScreen()),

    // ── Coach ──
    ShellRoute(
      builder: (_, __, child) => CoachShell(child: child),
      routes: [
        GoRoute(path: '/coach',               builder: (_, __) => const CoachDashboardScreen()),
        GoRoute(path: '/coach/members',       builder: (_, __) => const MembersListScreen()),
        GoRoute(path: '/coach/validations',   builder: (_, __) => const CoachValidationsScreen()),
        GoRoute(path: '/coach/planning',      builder: (_, __) => const PlanningScreen()),
        GoRoute(path: '/coach/absences',      builder: (_, __) => const AbsenceScreen()),
        GoRoute(path: '/coach/messages',      builder: (_, __) => const CoachMessagesScreen()),
        GoRoute(path: '/coach/events',         builder: (_, __) => const MemberEventsScreen()),
        GoRoute(path: '/coach/notifications', builder: (context, __) => NotificationsScreen(userId: auth.user?.id)),
        GoRoute(path: '/coach/complaints',    builder: (context, __) => ComplaintsScreen(userId: auth.user?.id)),
        GoRoute(path: '/coach/ratings',       builder: (context, __) => CoachRatingsScreen(userId: auth.user?.id ?? 0)),
        GoRoute(path: '/coach/profile',       builder: (_, __) => const CoachProfileScreen()),
      ],
    ),

    // ── Admin (legacy) ──
    ShellRoute(
      builder: (_, __, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin',           builder: (_, __) => const AdminDashboardPage()),
        GoRoute(path: '/admin/members',   builder: (_, __) => const AdminMembersPage()),
        GoRoute(path: '/admin/coaches',   builder: (_, __) => const AdminCoachesPage()),
        GoRoute(path: '/admin/payments',  builder: (_, __) => const AdminPaymentsPage()),
        GoRoute(path: '/admin/messages',  builder: (_, __) => const AdminMessagesScreen()),
        GoRoute(path: '/admin/courses',     builder: (_, __) => const AdminCoursesPage()),
        GoRoute(path: '/admin/reports',     builder: (_, __) => const AdminReportsScreen()),
        GoRoute(path: '/admin/profile',     builder: (_, __) => const AdminProfilePage()),
        GoRoute(path: '/admin/complaints',  builder: (_, __) => const AdminComplaintsPage()),
        GoRoute(path: '/admin/absences',    builder: (_, __) => const AdminAbsencesPage()),
        GoRoute(path: '/admin/qr-display',  builder: (_, __) => const QrDisplayScreen()),
      ],
    ),
  ],
);
