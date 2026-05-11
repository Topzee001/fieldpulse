import 'package:fieldpulse/src/features/auth/views/login_screen.dart';
import 'package:fieldpulse/src/features/auth/views/register_screen.dart';
import 'package:fieldpulse/src/features/jobs/views/job_detail_screen.dart';
import 'package:fieldpulse/src/features/jobs/views/job_list_screen.dart';
import 'package:fieldpulse/src/services/push_notification_service.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/jobs',
      name: 'jobs',
      builder: (context, state) => const JobListScreen(),
    ),
    GoRoute(
      path: '/jobs/:id',
      name: 'job-detail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return JobDetailScreen(jobId: id);
      },
    ),
  ],
);
