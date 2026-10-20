// App-wide constants for UniRide
class AppConstants {
  static const String appName = 'UniRide';
  static const String tagline = 'Your campus. Our ride.';
  static const String backendUrl = 'http://127.0.0.1:3000';

  // Reservation constants
  static const int maxCancellationsBeforePenalty = 2;
  static const int penaltyDurationDays = 7;
  static const int minRequestsForExtraBus = 15;
  static const int seatReservationTimeoutMinutes = 10;

  // SharedPreferences keys
  static const String keyCurrentUser = 'current_user';
  static const String keyUsers = 'users';
  static const String keyReservations = 'reservations';
  static const String keyBuses = 'buses';
  static const String keyRoutes = 'routes';
  static const String keyNotifications = 'notifications';
  static const String keyExtraBusRequests = 'extra_bus_requests';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyCancellations = 'cancellations';
  static const String keySchedules = 'schedules';
}

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String studentDashboard = '/student/dashboard';
  static const String driverDashboard = '/driver/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String routeSearch = '/route-search';
  static const String seatSelection = '/seat-selection';
  static const String myReservations = '/my-reservations';
  static const String qrScanner = '/qr-scanner';
  static const String qrDisplay = '/qr-display';
  static const String aiChat = '/ai-chat';
  static const String notifications = '/notifications';
  static const String schedule = '/schedule';
  static const String profile = '/profile';
  static const String adminUsers = '/admin/users';
  static const String adminBuses = '/admin/buses';
  static const String adminRoutes = '/admin/routes';
  static const String adminRequests = '/admin/requests';
  static const String driverRoute = '/driver/route';
  static const String driverScanner = '/driver/scanner';
}
