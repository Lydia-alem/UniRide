import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../models/bus_model.dart';
import '../../models/reservation_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const _AdminOverviewTab(),
        const _AdminBusesTab(),
        const _AdminUsersTab(),
        const _AdminRequestsTab(),
        const _AdminAITab(),
      ][_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.darkBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) =>
              setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_bus_outlined),
              selectedIcon: Icon(Icons.directions_bus_rounded),
              label: 'Buses',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.request_page_outlined),
              selectedIcon: Icon(Icons.request_page_rounded),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
              label: 'AI',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ───────────────────────────────────────────────────────────

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final totalStudents =
        provider.users.where((u) => u.role == UserRole.student).length;
    final activeReservations = provider.reservations
        .where((r) => r.isActive)
        .length;
    final pendingRequests =
        provider.extraBusRequests.where((r) => !r.isProcessed).length;
    final totalBuses = provider.buses.length;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refreshData,
          color: AppColors.orange,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.primaryGradient.createShader(b),
                      child: const Text(
                        'UniRide',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: const TextStyle(color: AppColors.textMuted),
                ),

                const SizedBox(height: 24),

                // Stat grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _AdminStat(
                      label: 'Students',
                      value: '$totalStudents',
                      icon: Icons.school_rounded,
                      gradient: AppColors.primaryGradient,
                    ),
                    _AdminStat(
                      label: 'Active Reservations',
                      value: '$activeReservations',
                      icon: Icons.confirmation_num_rounded,
                      gradient: AppColors.purpleGradient,
                    ),
                    _AdminStat(
                      label: 'Buses Today',
                      value: '$totalBuses',
                      icon: Icons.directions_bus_rounded,
                      gradient: const LinearGradient(
                          colors: [AppColors.teal, AppColors.blue]),
                    ),
                    _AdminStat(
                      label: 'Extra Requests',
                      value: '$pendingRequests',
                      icon: Icons.request_page_rounded,
                      gradient: const LinearGradient(
                          colors: [AppColors.warning, AppColors.orange]),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // Recent reservations
                const SectionHeader(title: 'Recent Reservations'),
                const SizedBox(height: 12),
                ...provider.reservations
                    .take(5)
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _AdminReservationRow(
                              reservation: r, provider: provider),
                        )),

                const SizedBox(height: 24),

                // Buses occupancy
                const SectionHeader(title: 'Fleet Status'),
                const SizedBox(height: 12),
                ...provider.buses.take(4).map((b) {
                  final route = provider.getRouteById(b.routeId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                route?.lineNumber ?? 'L?',
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${b.departureTime} — ${b.plateNumber}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              StatusChip(
                                label: b.status,
                                color: b.status == 'arrived'
                                    ? AppColors.success
                                    : b.status == 'en_route'
                                        ? AppColors.blue
                                        : AppColors.textSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OccupancyBar(
                            booked: b.bookedSeats,
                            total: b.totalSeats,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),
                // Logout
                GestureDetector(
                  onTap: () async {
                    await provider.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.login);
                    }
                  },
                  child: GlassCard(
                    child: Row(
                      children: const [
                        Icon(Icons.logout_rounded, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Sign Out',
                            style: TextStyle(color: AppColors.error)),
                        Spacer(),
                        Icon(Icons.chevron_right,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _AdminStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReservationRow extends StatelessWidget {
  final Reservation reservation;
  final AppProvider provider;

  const _AdminReservationRow({
    required this.reservation,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final user = provider.getUserById(reservation.userId);
    final statusColor = reservation.status == ReservationStatus.confirmed
        ? AppColors.success
        : reservation.status == ReservationStatus.cancelled
            ? AppColors.error
            : AppColors.warning;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (user?.name.substring(0, 1) ?? '?').toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Unknown',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${reservation.origin} → ${reservation.destination} · ${reservation.departureTime}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            label: reservation.status.name,
            color: statusColor,
          ),
        ],
      ),
    );
  }
}

// ─── Buses Tab ───────────────────────────────────────────────────────────────

class _AdminBusesTab extends StatelessWidget {
  const _AdminBusesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Fleet Management',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddBusDialog(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text('Add Bus',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.buses.isEmpty
                  ? const EmptyState(
                      icon: Icons.directions_bus_outlined,
                      title: 'No buses registered',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.buses.length,
                      itemBuilder: (context, i) {
                        final bus = provider.buses[i];
                        final route =
                            provider.getRouteById(bus.routeId);
                        final driver =
                            provider.getUserById(bus.driverId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      route?.lineNumber ?? 'L?',
                                      style: const TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        route?.name ?? 'Unknown',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    StatusChip(
                                      label: bus.status,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.badge_outlined,
                                        size: 14,
                                        color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      bus.plateNumber,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.person_outline,
                                        size: 14,
                                        color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      driver?.name ?? 'No driver',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                OccupancyBar(
                                  booked: bus.bookedSeats,
                                  total: bus.totalSeats,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBusDialog(BuildContext context, AppProvider provider) {
    final plateCtrl = TextEditingController();
    String? selectedRouteId = provider.routes.isNotEmpty
        ? provider.routes.first.id
        : null;
    String? selectedDriverId = provider.users
        .where((u) => u.role == UserRole.driver)
        .map((u) => u.id)
        .firstOrNull;
    final timeCtrl = TextEditingController(text: '08:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Add New Bus',
            style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: plateCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Plate Number'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRouteId,
                dropdownColor: AppColors.darkCard,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Route'),
                items: provider.routes
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name),
                        ))
                    .toList(),
                onChanged: (v) => selectedRouteId = v,
              ),
              const SizedBox(height: 12),
              if (provider.users
                  .any((u) => u.role == UserRole.driver))
                DropdownButtonFormField<String>(
                  value: selectedDriverId,
                  dropdownColor: AppColors.darkCard,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Driver'),
                  items: provider.users
                      .where((u) => u.role == UserRole.driver)
                      .map((u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.name),
                          ))
                      .toList(),
                  onChanged: (v) => selectedDriverId = v,
                ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(labelText: 'Departure Time (HH:MM)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedRouteId == null || selectedDriverId == null) {
                return;
              }
              final route = provider.getRouteById(selectedRouteId!);
              final bus = Bus(
                routeId: selectedRouteId!,
                plateNumber: plateCtrl.text.isEmpty
                    ? 'TBD-000'
                    : plateCtrl.text.toUpperCase(),
                driverId: selectedDriverId!,
                departureTime: timeCtrl.text.isEmpty
                    ? '08:00'
                    : timeCtrl.text,
                departureDate: DateTime.now(),
                totalSeats: route?.totalSeats ?? 40,
                standingAllowed: route?.standingAllowed ?? false,
                maxStanding: route?.maxStanding ?? 0,
              );
              await provider.addBus(bus);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Bus'),
          ),
        ],
      ),
    );
  }
}

// ─── Users Tab ───────────────────────────────────────────────────────────────

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users =
        provider.users.where((u) => u.id != provider.currentUser?.id).toList();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'User Management',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Role filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final role in UserRole.values)
                    Chip(
                      label: Text(
                        '${role.name.toUpperCase()} (${users.where((u) => u.role == role).length})',
                      ),
                      backgroundColor: AppColors.darkCard,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: user.role == UserRole.student
                                  ? AppColors.primaryGradient
                                  : user.role == UserRole.driver
                                      ? AppColors.purpleGradient
                                      : const LinearGradient(
                                          colors: [
                                              AppColors.teal,
                                              AppColors.blue
                                            ]),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (user.isPenalized)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppColors.error,
                                          size: 14,
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (user.studentId != null)
                                  Text(
                                    user.studentId!,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          StatusChip(
                            label: user.role.name,
                            color: user.role == UserRole.student
                                ? AppColors.orange
                                : user.role == UserRole.driver
                                    ? AppColors.blue
                                    : AppColors.purple,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Requests Tab ─────────────────────────────────────────────────────────────

class _AdminRequestsTab extends StatelessWidget {
  const _AdminRequestsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final requests = provider.extraBusRequests
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Group by destination/date
    final Map<String, List<dynamic>> grouped = {};
    for (final req in requests) {
      final key =
          '${req.destination}_${req.requestedDate.day}${req.requestedDate.month}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(req);
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Extra Bus Requests',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${requests.where((r) => !r.isProcessed).length} pending • Threshold: ${AppConstants.minRequestsForExtraBus} requests',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: requests.isEmpty
                  ? const EmptyState(
                      icon: Icons.directions_bus_outlined,
                      title: 'No requests yet',
                      subtitle:
                          'When buses are full, students can request extra buses',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: grouped.length,
                      itemBuilder: (context, i) {
                        final group =
                            grouped.values.toList()[i];
                        final first = group.first;
                        final count = group.length;
                        final isThresholdMet =
                            count >= AppConstants.minRequestsForExtraBus;
                        final isProcessed =
                            first.isProcessed == true;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            borderColor: isThresholdMet && !isProcessed
                                ? AppColors.warning.withOpacity(0.5)
                                : null,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isThresholdMet && !isProcessed)
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.warning,
                                        size: 18,
                                      ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        first.destination,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: isThresholdMet
                                            ? const LinearGradient(
                                                colors: [
                                                    AppColors.warning,
                                                    AppColors.orange
                                                  ])
                                            : null,
                                        color: isThresholdMet
                                            ? null
                                            : AppColors.darkNavy,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$count requests',
                                        style: TextStyle(
                                          color: isThresholdMet
                                              ? Colors.white
                                              : AppColors.textMuted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 12,
                                        color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('MMM d, y').format(
                                          first.requestedDate),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.access_time,
                                        size: 12,
                                        color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      first.requestedTime,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                // Progress bar
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (count /
                                            AppConstants
                                                .minRequestsForExtraBus)
                                        .clamp(0.0, 1.0),
                                    backgroundColor:
                                        AppColors.darkNavy,
                                    color: isThresholdMet
                                        ? AppColors.warning
                                        : AppColors.orange,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count / ${AppConstants.minRequestsForExtraBus} threshold',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),

                                if (isThresholdMet && !isProcessed) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        for (final req in group) {
                                          await provider
                                              .processExtraBusRequest(
                                                  req.id);
                                        }
                                      },
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 16),
                                      label: const Text(
                                          'Dispatch Extra Bus'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.warning,
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                  ),
                                ] else if (isProcessed)
                                  const StatusChip(
                                    label: 'Processed',
                                    color: AppColors.success,
                                    icon: Icons.check_circle,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin AI Tab ─────────────────────────────────────────────────────────────

class _AdminAITab extends StatefulWidget {
  const _AdminAITab();

  @override
  State<_AdminAITab> createState() => _AdminAITabState();
}

class _AdminAITabState extends State<_AdminAITab> {
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          '⚙️ Hello Admin! I can help you analyze ridership patterns, identify demand trends, manage fleet allocation, and answer transport policy questions.',
    }
  ];
  bool _loading = false;

  final List<String> _adminSuggestions = [
    'Which routes have highest demand?',
    'Predict tomorrow\'s peak hours',
    'How to reduce cancellation rates?',
    'Suggest optimal bus dispatch schedule',
  ];

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });

    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    setState(() {
      _messages.add({
        'role': 'ai',
        'text':
            'Based on the system data, I can provide insights. Connect to the full AI backend for real-time analytics and predictions.',
      });
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.teal, AppColors.blue]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Admin AI Analytics',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Analyzing...',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    );
                  }
                  final m = _messages[i];
                  final isUser = m['role'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.8,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? AppColors.primaryGradient
                              : null,
                          color: isUser ? null : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: isUser
                              ? null
                              : Border.all(color: AppColors.darkBorder),
                        ),
                        child: Text(
                          m['text']!,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Suggestion chips
            if (_messages.length == 1)
              SizedBox(
                height: 50,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: _adminSuggestions
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(s,
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: () => _send(s),
                              backgroundColor: AppColors.darkCard,
                              side: const BorderSide(
                                  color: AppColors.teal),
                              labelStyle:
                                  const TextStyle(color: AppColors.teal),
                            ),
                          ))
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask for analytics or insights...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(_ctrl.text),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.teal, AppColors.blue]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
