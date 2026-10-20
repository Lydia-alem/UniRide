import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/bus_model.dart';
import '../models/reservation_model.dart';
import '../models/notification_model.dart';
import '../services/storage_service.dart';
import '../core/constants.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage;

  AppUser? _currentUser;
  List<AppUser> _users = [];
  List<Bus> _buses = [];
  List<BusRoute> _routes = [];
  List<Reservation> _reservations = [];
  List<AppNotification> _notifications = [];
  List<ExtraBusRequest> _extraBusRequests = [];
  List<ClassSchedule> _schedules = [];

  bool _isLoading = false;
  String? _error;

  AppProvider(this._storage);

  // ─── Getters ─────────────────────────────────────────────────────────────
  AppUser? get currentUser => _currentUser;
  List<AppUser> get users => _users;
  List<Bus> get buses => _buses;
  List<BusRoute> get routes => _routes;
  List<Reservation> get reservations => _reservations;
  List<AppNotification> get notifications => _notifications;
  List<ExtraBusRequest> get extraBusRequests => _extraBusRequests;
  List<ClassSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<Reservation> get myReservations =>
      _reservations.where((r) => r.userId == _currentUser?.id).toList();

  List<Reservation> get myActiveReservations => myReservations
      .where((r) =>
          r.status == ReservationStatus.confirmed ||
          r.status == ReservationStatus.pending)
      .toList();

  // ─── Initialization ──────────────────────────────────────────────────────

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _storage.seedDataIfEmpty();
      _currentUser = await _storage.getCurrentUser();
      _users = await _storage.getUsers();
      _buses = await _storage.getBuses();
      _routes = await _storage.getRoutes();
      _reservations = await _storage.getReservations();
      _extraBusRequests = await _storage.getExtraBusRequests();
      if (_currentUser != null) {
        _notifications = await _storage.getNotifications(_currentUser!.id);
        _schedules = await _storage.getUserSchedules(_currentUser!.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Auth ────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await _storage.login(email, password);
      if (user != null) {
        _currentUser = user;
        _notifications = await _storage.getNotifications(user.id);
        _schedules = await _storage.getUserSchedules(user.id);
        _reservations = await _storage.getReservations();
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password.';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(AppUser user) async {
    _setLoading(true);
    _error = null;
    try {
      final created = await _storage.register(user);
      if (created != null) {
        _currentUser = created;
        _users = await _storage.getUsers();
        notifyListeners();
        return true;
      } else {
        _error = 'Email already registered.';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _storage.setCurrentUser(null);
    _currentUser = null;
    _notifications = [];
    _schedules = [];
    notifyListeners();
  }

  // ─── Reservations ────────────────────────────────────────────────────────

  Future<String?> createReservation({
    required String busId,
    required String seatNumber,
    required SeatType seatType,
  }) async {
    if (_currentUser == null) return 'Not logged in';
    if (_currentUser!.isPenalized) {
      return 'You are under a penalty until ${_currentUser!.penaltyUntil!.toLocal().toString().split(' ')[0]}. Reservations are suspended.';
    }

    final bus = _buses.firstWhere((b) => b.id == busId);
    final route = _routes.firstWhere((r) => r.id == bus.routeId);

    // Check if user already has a reservation for this bus
    final existing = _reservations.where(
      (r) =>
          r.userId == _currentUser!.id &&
          r.busId == busId &&
          r.isActive,
    );
    if (existing.isNotEmpty) {
      return 'You already have an active reservation on this bus.';
    }

    // Check seat availability
    if (seatType == SeatType.seated && bus.availableSeats <= 0) {
      return 'No seated spots available.';
    }
    if (seatType == SeatType.standing &&
        (!bus.standingAllowed || bus.availableStanding <= 0)) {
      return 'No standing spots available.';
    }

    final reservation = Reservation(
      userId: _currentUser!.id,
      busId: busId,
      routeId: bus.routeId,
      seatNumber: seatNumber,
      seatType: seatType,
      status: ReservationStatus.pending,
      departureTime: bus.departureTime,
      departureDate: bus.departureDate,
      origin: route.origin,
      destination: route.destination,
    );

    await _storage.addReservation(reservation);
    _reservations.add(reservation);

    // Update bus seats
    final updatedBus = seatType == SeatType.seated
        ? bus.copyWith(bookedSeats: bus.bookedSeats + 1)
        : bus.copyWith(standingBooked: bus.standingBooked + 1);
    await _storage.updateBus(updatedBus);
    final idx = _buses.indexWhere((b) => b.id == busId);
    if (idx != -1) _buses[idx] = updatedBus;

    // Add notification
    await _addNotification(
      title: 'Reservation Pending',
      body: 'Your reservation for seat $seatNumber on ${bus.departureTime} is pending confirmation.',
      type: NotificationType.reservation,
    );

    notifyListeners();
    return null; // Success
  }

  Future<String?> confirmReservation(String reservationId) async {
    final idx = _reservations.indexWhere((r) => r.id == reservationId);
    if (idx == -1) return 'Reservation not found';

    final updated = _reservations[idx].copyWith(
      status: ReservationStatus.confirmed,
      confirmedAt: DateTime.now(),
    );
    await _storage.updateReservation(updated);
    _reservations[idx] = updated;

    await _addNotification(
      title: 'Reservation Confirmed ✓',
      body: 'Seat ${updated.seatNumber} on ${updated.departureTime} — ${updated.origin} → ${updated.destination}',
      type: NotificationType.reservation,
    );

    notifyListeners();
    return null;
  }

  Future<String?> cancelReservation(String reservationId,
      {String? reason}) async {
    if (_currentUser == null) return 'Not logged in';

    final idx = _reservations.indexWhere((r) => r.id == reservationId);
    if (idx == -1) return 'Reservation not found';

    final res = _reservations[idx];
    if (!res.isActive) return 'Reservation is not active';

    final updated = res.copyWith(
      status: ReservationStatus.cancelled,
      cancelledAt: DateTime.now(),
      cancellationReason: reason,
    );
    await _storage.updateReservation(updated);
    _reservations[idx] = updated;

    // Free the seat
    final busIdx = _buses.indexWhere((b) => b.id == res.busId);
    if (busIdx != -1) {
      final bus = _buses[busIdx];
      final updatedBus = res.seatType == SeatType.seated
          ? bus.copyWith(bookedSeats: (bus.bookedSeats - 1).clamp(0, 9999))
          : bus.copyWith(standingBooked: (bus.standingBooked - 1).clamp(0, 9999));
      await _storage.updateBus(updatedBus);
      _buses[busIdx] = updatedBus;
    }

    // Track cancellation count and apply penalty if needed
    final newCount = _currentUser!.cancellationCount + 1;
    AppUser updatedUser = _currentUser!.copyWith(cancellationCount: newCount);

    if (newCount >= AppConstants.maxCancellationsBeforePenalty) {
      final penaltyUntil = DateTime.now().add(
        const Duration(days: AppConstants.penaltyDurationDays),
      );
      updatedUser = updatedUser.copyWith(
        penaltyUntil: penaltyUntil,
        cancellationCount: 0,
      );
      await _addNotification(
        title: '⚠️ Penalty Applied',
        body: 'Too many cancellations. Reservations suspended for ${AppConstants.penaltyDurationDays} days.',
        type: NotificationType.penalty,
      );
    } else {
      await _addNotification(
        title: 'Reservation Cancelled',
        body: 'Seat ${res.seatNumber} has been released. Warning: ${AppConstants.maxCancellationsBeforePenalty - newCount} more cancellations allowed before penalty.',
        type: NotificationType.cancellation,
      );
    }

    await _storage.updateUser(updatedUser);
    _currentUser = updatedUser;

    notifyListeners();
    return null;
  }

  Future<void> markBoarded(String reservationId) async {
    final idx = _reservations.indexWhere((r) => r.id == reservationId);
    if (idx == -1) return;

    final updated = _reservations[idx].copyWith(
      status: ReservationStatus.boarded,
      boardedAt: DateTime.now(),
    );
    await _storage.updateReservation(updated);
    _reservations[idx] = updated;
    notifyListeners();
  }

  // ─── Extra Bus Requests ──────────────────────────────────────────────────

  Future<void> requestExtraBus({
    required String routeId,
    required String destination,
    required DateTime date,
    required String time,
  }) async {
    if (_currentUser == null) return;

    final req = ExtraBusRequest(
      userId: _currentUser!.id,
      routeId: routeId,
      destination: destination,
      requestedDate: date,
      requestedTime: time,
    );
    await _storage.addExtraBusRequest(req);
    _extraBusRequests.add(req);

    // Check threshold
    final matching = _extraBusRequests.where(
      (r) =>
          r.destination == destination &&
          r.requestedDate.day == date.day &&
          r.requestedDate.month == date.month &&
          !r.isProcessed,
    );
    if (matching.length >= AppConstants.minRequestsForExtraBus) {
      // Notify all admins
      final admins = _users.where((u) => u.role == UserRole.admin);
      for (final admin in admins) {
        await _storage.addNotification(AppNotification(
          userId: admin.id,
          title: '🚌 Extra Bus Needed',
          body: '${matching.length} students requested an extra bus to $destination on ${date.toLocal().toString().split(' ')[0]}',
          type: NotificationType.extraBus,
        ));
      }
    }

    await _addNotification(
      title: 'Extra Bus Requested',
      body: 'Your request for an extra bus to $destination has been submitted.',
      type: NotificationType.extraBus,
    );

    notifyListeners();
  }

  // ─── Schedules ───────────────────────────────────────────────────────────

  Future<void> saveSchedule(ClassSchedule schedule) async {
    await _storage.saveSchedule(schedule);
    final idx = _schedules.indexWhere((s) => s.id == schedule.id);
    if (idx != -1) {
      _schedules[idx] = schedule;
    } else {
      _schedules.add(schedule);
    }
    notifyListeners();
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _storage.deleteSchedule(scheduleId);
    _schedules.removeWhere((s) => s.id == scheduleId);
    notifyListeners();
  }

  // ─── Admin ───────────────────────────────────────────────────────────────

  Future<void> addBus(Bus bus) async {
    final buses = await _storage.getBuses();
    buses.add(bus);
    await _storage.saveBuses(buses);
    _buses = buses;
    notifyListeners();
  }

  Future<void> updateBusStatus(String busId, String status) async {
    final idx = _buses.indexWhere((b) => b.id == busId);
    if (idx != -1) {
      final updated = _buses[idx].copyWith(status: status);
      await _storage.updateBus(updated);
      _buses[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> addRoute(BusRoute route) async {
    final routes = await _storage.getRoutes();
    routes.add(route);
    await _storage.saveRoutes(routes);
    _routes = routes;
    notifyListeners();
  }

  Future<void> processExtraBusRequest(String requestId) async {
    final idx = _extraBusRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final updated = _extraBusRequests[idx].copyWith(isProcessed: true);
      await _storage.updateExtraBusRequest(updated);
      _extraBusRequests[idx] = updated;
      notifyListeners();
    }
  }

  // ─── Notifications ───────────────────────────────────────────────────────

  Future<void> _addNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    if (_currentUser == null) return;
    final notification = AppNotification(
      userId: _currentUser!.id,
      title: title,
      body: body,
      type: type,
    );
    await _storage.addNotification(notification);
    _notifications.insert(0, notification);
  }

  Future<void> markNotificationRead(String id) async {
    await _storage.markNotificationRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  BusRoute? getRouteById(String id) {
    try {
      return _routes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Bus? getBusById(String id) {
    try {
      return _buses.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Bus> getBusesForRoute(String routeId) =>
      _buses.where((b) => b.routeId == routeId && b.isActive).toList();

  List<String> getTakenSeats(String busId) {
    return _reservations
        .where((r) => r.busId == busId && r.isActive)
        .map((r) => r.seatNumber)
        .toList();
  }

  AppUser? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshData() async {
    _buses = await _storage.getBuses();
    _reservations = await _storage.getReservations();
    _users = await _storage.getUsers();
    if (_currentUser != null) {
      _notifications = await _storage.getNotifications(_currentUser!.id);
      final updated = _users.firstWhere(
        (u) => u.id == _currentUser!.id,
        orElse: () => _currentUser!,
      );
      _currentUser = updated;
    }
    notifyListeners();
  }
}
