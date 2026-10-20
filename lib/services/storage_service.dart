import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/bus_model.dart';
import '../models/reservation_model.dart';
import '../models/notification_model.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ─── Users ───────────────────────────────────────────────────────────────

  Future<List<AppUser>> getUsers() async {
    final raw = _prefs!.getString(AppConstants.keyUsers) ?? '[]';
    final list = jsonDecode(raw) as List;
    return list.map((e) => AppUser.fromJson(e)).toList();
  }

  Future<void> saveUsers(List<AppUser> users) async {
    await _prefs!.setString(
      AppConstants.keyUsers,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<AppUser?> getCurrentUser() async {
    final raw = _prefs!.getString(AppConstants.keyCurrentUser);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw));
  }

  Future<void> setCurrentUser(AppUser? user) async {
    if (user == null) {
      await _prefs!.remove(AppConstants.keyCurrentUser);
    } else {
      await _prefs!.setString(
        AppConstants.keyCurrentUser,
        jsonEncode(user.toJson()),
      );
    }
  }

  Future<AppUser?> login(String email, String password) async {
    final users = await getUsers();
    try {
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() &&
            u.password == password,
      );
      await setCurrentUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> register(AppUser user) async {
    final users = await getUsers();
    if (users.any(
        (u) => u.email.toLowerCase() == user.email.toLowerCase())) {
      return null; // Email taken
    }
    users.add(user);
    await saveUsers(users);
    await setCurrentUser(user);
    return user;
  }

  Future<void> updateUser(AppUser user) async {
    final users = await getUsers();
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      users[idx] = user;
      await saveUsers(users);
      final current = await getCurrentUser();
      if (current?.id == user.id) {
        await setCurrentUser(user);
      }
    }
  }

  // ─── Buses ───────────────────────────────────────────────────────────────

  Future<List<Bus>> getBuses() async {
    final raw = _prefs!.getString(AppConstants.keyBuses) ?? '[]';
    final list = jsonDecode(raw) as List;
    return list.map((e) => Bus.fromJson(e)).toList();
  }

  Future<void> saveBuses(List<Bus> buses) async {
    await _prefs!.setString(
      AppConstants.keyBuses,
      jsonEncode(buses.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> updateBus(Bus bus) async {
    final buses = await getBuses();
    final idx = buses.indexWhere((b) => b.id == bus.id);
    if (idx != -1) {
      buses[idx] = bus;
      await saveBuses(buses);
    }
  }

  // ─── Routes ──────────────────────────────────────────────────────────────

  Future<List<BusRoute>> getRoutes() async {
    final raw = _prefs!.getString(AppConstants.keyRoutes) ?? '[]';
    final list = jsonDecode(raw) as List;
    return list.map((e) => BusRoute.fromJson(e)).toList();
  }

  Future<void> saveRoutes(List<BusRoute> routes) async {
    await _prefs!.setString(
      AppConstants.keyRoutes,
      jsonEncode(routes.map((r) => r.toJson()).toList()),
    );
  }

  // ─── Reservations ────────────────────────────────────────────────────────

  Future<List<Reservation>> getReservations() async {
    final raw = _prefs!.getString(AppConstants.keyReservations) ?? '[]';
    final list = jsonDecode(raw) as List;
    return list.map((e) => Reservation.fromJson(e)).toList();
  }

  Future<void> saveReservations(List<Reservation> reservations) async {
    await _prefs!.setString(
      AppConstants.keyReservations,
      jsonEncode(reservations.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> addReservation(Reservation res) async {
    final all = await getReservations();
    all.add(res);
    await saveReservations(all);
  }

  Future<void> updateReservation(Reservation res) async {
    final all = await getReservations();
    final idx = all.indexWhere((r) => r.id == res.id);
    if (idx != -1) {
      all[idx] = res;
      await saveReservations(all);
    }
  }

  Future<List<Reservation>> getUserReservations(String userId) async {
    final all = await getReservations();
    return all.where((r) => r.userId == userId).toList();
  }

  Future<List<Reservation>> getBusReservations(String busId) async {
    final all = await getReservations();
    return all.where((r) => r.busId == busId).toList();
  }

  // ─── Notifications ───────────────────────────────────────────────────────

  Future<List<AppNotification>> getNotifications(String userId) async {
    final raw = _prefs!.getString(AppConstants.keyNotifications) ?? '[]';
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AppNotification.fromJson(e))
        .where((n) => n.userId == userId)
        .toList();
  }

  Future<void> _saveAllNotifications(
      List<AppNotification> notifications) async {
    await _prefs!.setString(
      AppConstants.keyNotifications,
      jsonEncode(notifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> addNotification(AppNotification notification) async {
    final raw = _prefs!.getString(AppConstants.keyNotifications) ?? '[]';
    final list = jsonDecode(raw) as List;
    final all = list.map((e) => AppNotification.fromJson(e)).toList();
    all.add(notification);
    await _saveAllNotifications(all);
  }

  Future<void> markNotificationRead(String notificationId) async {
    final raw = _prefs!.getString(AppConstants.keyNotifications) ?? '[]';
    final list = jsonDecode(raw) as List;
    final all = list.map((e) => AppNotification.fromJson(e)).toList();
    final idx = all.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      all[idx] = all[idx].copyWith(isRead: true);
      await _saveAllNotifications(all);
    }
  }

  // ─── Extra Bus Requests ──────────────────────────────────────────────────

  Future<List<ExtraBusRequest>> getExtraBusRequests() async {
    final raw = _prefs!.getString(AppConstants.keyExtraBusRequests) ?? '[]';
    final list = jsonDecode(raw) as List;
    return list.map((e) => ExtraBusRequest.fromJson(e)).toList();
  }

  Future<void> addExtraBusRequest(ExtraBusRequest req) async {
    final all = await getExtraBusRequests();
    all.add(req);
    await _prefs!.setString(
      AppConstants.keyExtraBusRequests,
      jsonEncode(all.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> updateExtraBusRequest(ExtraBusRequest req) async {
    final all = await getExtraBusRequests();
    final idx = all.indexWhere((r) => r.id == req.id);
    if (idx != -1) {
      all[idx] = req;
      await _prefs!.setString(
        AppConstants.keyExtraBusRequests,
        jsonEncode(all.map((r) => r.toJson()).toList()),
      );
    }
  }

  // ─── Class Schedules ─────────────────────────────────────────────────────

  Future<List<ClassSchedule>> getUserSchedules(String userId) async {
    final raw = _prefs!.getString(AppConstants.keySchedules) ?? '[]';
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ClassSchedule.fromJson(e))
        .where((s) => s.userId == userId)
        .toList();
  }

  Future<void> saveSchedule(ClassSchedule schedule) async {
    final raw = _prefs!.getString(AppConstants.keySchedules) ?? '[]';
    final list = jsonDecode(raw) as List;
    final all = list.map((e) => ClassSchedule.fromJson(e)).toList();
    final idx = all.indexWhere((s) => s.id == schedule.id);
    if (idx != -1) {
      all[idx] = schedule;
    } else {
      all.add(schedule);
    }
    await _prefs!.setString(
      AppConstants.keySchedules,
      jsonEncode(all.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final raw = _prefs!.getString(AppConstants.keySchedules) ?? '[]';
    final list = jsonDecode(raw) as List;
    final all = list
        .map((e) => ClassSchedule.fromJson(e))
        .where((s) => s.id != scheduleId)
        .toList();
    await _prefs!.setString(
      AppConstants.keySchedules,
      jsonEncode(all.map((s) => s.toJson()).toList()),
    );
  }

  // ─── Onboarding ──────────────────────────────────────────────────────────

  bool get onboardingDone =>
      _prefs!.getBool(AppConstants.keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone() async {
    await _prefs!.setBool(AppConstants.keyOnboardingDone, true);
  }

  // ─── Seed Data ───────────────────────────────────────────────────────────

  Future<void> seedDataIfEmpty() async {
    final users = await getUsers();
    if (users.isEmpty) {
      // Seed default users
      final admin = AppUser(
        id: 'admin-001',
        name: 'Admin UniRide',
        email: 'admin@uniride.edu',
        password: 'admin123',
        role: UserRole.admin,
        university: 'Université de Paris',
      );
      final driver = AppUser(
        id: 'driver-001',
        name: 'Mohammed Alaoui',
        email: 'driver@uniride.edu',
        password: 'driver123',
        role: UserRole.driver,
        phone: '+33 6 12 34 56 78',
      );
      final student = AppUser(
        id: 'student-001',
        name: 'Lydia Benali',
        email: 'student@uniride.edu',
        password: 'student123',
        role: UserRole.student,
        studentId: 'STU-2024-001',
        university: 'Université de Paris',
      );
      await saveUsers([admin, driver, student]);
    }

    final routes = await getRoutes();
    if (routes.isEmpty) {
      final route1 = BusRoute(
        id: 'route-001',
        name: 'Campus Express',
        lineNumber: 'L1',
        stops: ['Cité Universitaire', 'Denfert-Rochereau', 'Port-Royal', 'Luxembourg', 'Campus Central'],
        origin: 'Cité Universitaire',
        destination: 'Campus Central',
        departureTimes: ['07:00', '07:30', '08:00', '08:30', '09:00', '12:00', '14:00', '17:00', '18:30'],
        totalSeats: 40,
        standingAllowed: true,
        maxStanding: 10,
      );
      final route2 = BusRoute(
        id: 'route-002',
        name: 'Science Line',
        lineNumber: 'L2',
        stops: ['Gare du Nord', 'Châtelet', 'Saint-Michel', 'Campus Sciences', 'Bibliothèque'],
        origin: 'Gare du Nord',
        destination: 'Bibliothèque',
        departureTimes: ['07:15', '08:15', '09:15', '13:00', '15:00', '17:30', '19:00'],
        totalSeats: 35,
        standingAllowed: false,
        maxStanding: 0,
      );
      final route3 = BusRoute(
        id: 'route-003',
        name: 'Night Owl',
        lineNumber: 'L3',
        stops: ['Campus Central', 'Montparnasse', 'Saint-Germain', 'Bastille'],
        origin: 'Campus Central',
        destination: 'Bastille',
        departureTimes: ['20:00', '21:00', '22:00', '23:00'],
        totalSeats: 30,
        standingAllowed: true,
        maxStanding: 15,
      );
      await saveRoutes([route1, route2, route3]);

      // Seed some buses
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final buses = [
        Bus(
          id: 'bus-001',
          routeId: 'route-001',
          plateNumber: 'AB-123-CD',
          driverId: 'driver-001',
          departureTime: '08:00',
          departureDate: today,
          totalSeats: 40,
          bookedSeats: 22,
          standingAllowed: true,
          maxStanding: 10,
          standingBooked: 3,
          status: 'scheduled',
        ),
        Bus(
          id: 'bus-002',
          routeId: 'route-001',
          plateNumber: 'EF-456-GH',
          driverId: 'driver-001',
          departureTime: '08:30',
          departureDate: today,
          totalSeats: 40,
          bookedSeats: 38,
          standingAllowed: true,
          maxStanding: 10,
          standingBooked: 8,
          status: 'scheduled',
        ),
        Bus(
          id: 'bus-003',
          routeId: 'route-002',
          plateNumber: 'IJ-789-KL',
          driverId: 'driver-001',
          departureTime: '08:15',
          departureDate: today,
          totalSeats: 35,
          bookedSeats: 10,
          standingAllowed: false,
          status: 'scheduled',
        ),
        Bus(
          id: 'bus-004',
          routeId: 'route-001',
          plateNumber: 'MN-012-OP',
          driverId: 'driver-001',
          departureTime: '17:00',
          departureDate: today,
          totalSeats: 40,
          bookedSeats: 5,
          standingAllowed: true,
          maxStanding: 10,
          status: 'scheduled',
        ),
      ];
      await saveBuses(buses);
    }
  }
}
