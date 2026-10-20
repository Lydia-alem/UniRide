import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'models/user_model.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'services/gemma_service.dart';

// Screens
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/student/seat_selection_screen.dart';
import 'screens/student/qr_display_screen.dart';
import 'screens/student/route_search_screen.dart';
import 'screens/student/notifications_screen.dart';
import 'screens/student/schedule_screen.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.darkSurface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final storage = await StorageService.getInstance();
  final provider = AppProvider(storage);
  await provider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        Provider<GemmaService>(create: (_) => GemmaService()),
      ],
      child: const UniRideApp(),
    ),
  );
}

class UniRideApp extends StatelessWidget {
  const UniRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _SplashRouter(),
      routes: {
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.studentDashboard: (_) => const StudentDashboard(),
        AppRoutes.driverDashboard: (_) => const DriverDashboard(),
        AppRoutes.adminDashboard: (_) => const AdminDashboard(),
        AppRoutes.routeSearch: (_) => const RouteSearchScreen(),
        AppRoutes.seatSelection: (_) => const SeatSelectionScreen(),
        AppRoutes.qrDisplay: (_) => const QRDisplayScreen(),
        AppRoutes.notifications: (_) => const NotificationsScreen(),
        AppRoutes.schedule: (_) => const ScheduleScreen(),
      },
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final storage = await StorageService.getInstance();
    final provider = context.read<AppProvider>();

    // Check if already logged in
    final currentUser = provider.currentUser;
    if (currentUser != null) {
      _routeByRole(currentUser.role);
      return;
    }

    // Check onboarding
    if (!storage.onboardingDone) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _routeByRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
      case UserRole.driver:
        Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard);
      case UserRole.admin:
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66FF6B35),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 800.ms),

              const SizedBox(height: 24),

              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'UniRide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              const Text(
                'Your campus. Our ride.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 60),

              // Loading indicator
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    backgroundColor: AppColors.darkCard,
                    color: AppColors.orange,
                    minHeight: 3,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
