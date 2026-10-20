import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/reservation_model.dart';
import '../../models/bus_model.dart';
import '../../providers/app_provider.dart';
import '../../services/gemma_service.dart';
import '../../widgets/common_widgets.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const _RoutesTab(),
      const _MyTripsTab(),
      const _AIChatTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.darkBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Routes',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_num_outlined),
              selectedIcon: Icon(Icons.confirmation_num_rounded),
              label: 'My Trips',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
              label: 'AI Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ──────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final activeRes = provider.myActiveReservations;
    final unread = provider.unreadNotifications.length;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting,',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                          Text(
                            user.name.split(' ').first,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.notifications),
                          icon: const Icon(Icons.notifications_outlined,
                              size: 26),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.darkCard,
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                // Penalty warning
                if (user.isPenalized)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Reservation penalty active until ${DateFormat('MMM d, yyyy').format(user.penaltyUntil!)}.',
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake(),

                // Active reservation card
                if (activeRes.isNotEmpty) ...[
                  const SectionHeader(title: 'Next Ride'),
                  const SizedBox(height: 12),
                  _ActiveReservationCard(reservation: activeRes.first),
                  const SizedBox(height: 24),
                ],

                // Quick actions
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _QuickAction(
                      icon: Icons.search_rounded,
                      label: 'Find a Bus',
                      gradient: AppColors.primaryGradient,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.routeSearch),
                    ),
                    _QuickAction(
                      icon: Icons.qr_code_scanner,
                      label: 'My QR Code',
                      gradient: AppColors.purpleGradient,
                      onTap: () {
                        if (activeRes.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.qrDisplay,
                            arguments: activeRes.first,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No active reservation'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    _QuickAction(
                      icon: Icons.smart_toy_rounded,
                      label: 'Ask AI',
                      gradient: const LinearGradient(
                        colors: [AppColors.teal, AppColors.blue],
                      ),
                      onTap: () {}, // Tab switch handled by nav bar
                    ),
                    _QuickAction(
                      icon: Icons.calendar_today_rounded,
                      label: 'Schedule',
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.magenta],
                      ),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.schedule),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Today's buses
                SectionHeader(
                  title: "Today's Buses",
                  action: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.routeSearch),
                    child: const Text('View all',
                        style: TextStyle(color: AppColors.orange)),
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildTodaysBuses(context, provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTodaysBuses(BuildContext context, AppProvider provider) {
    final today = DateTime.now();
    final buses = provider.buses
        .where((b) =>
            b.isActive &&
            b.departureDate.day == today.day &&
            b.departureDate.month == today.month)
        .take(3)
        .toList();

    if (buses.isEmpty) {
      return [
        const EmptyState(
          icon: Icons.directions_bus_outlined,
          title: 'No buses scheduled today',
        ),
      ];
    }

    return buses.asMap().entries.map((entry) {
      final bus = entry.value;
      final route = provider.getRouteById(bus.routeId);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _BusCard(bus: bus, route: route),
      ).animate().fadeIn(delay: Duration(milliseconds: 300 + entry.key * 100));
    }).toList();
  }
}

class _ActiveReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ActiveReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.qrDisplay,
        arguments: reservation,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_num_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Active Reservation',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reservation.seatType == SeatType.standing
                        ? 'Standing'
                        : 'Seat ${reservation.seatNumber}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        reservation.origin,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('To',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        reservation.destination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(reservation.departureTime,
                    style: const TextStyle(color: Colors.white)),
                const Spacer(),
                const Icon(Icons.qr_code_2_rounded, color: Colors.white70),
                const SizedBox(width: 4),
                const Text('Tap to view QR',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusCard extends StatelessWidget {
  final Bus bus;
  final BusRoute? route;

  const _BusCard({required this.bus, this.route});

  @override
  Widget build(BuildContext context) {
    final ratio = bus.totalSeats > 0 ? bus.bookedSeats / bus.totalSeats : 0.0;
    final statusColor = ratio < 0.5
        ? AppColors.success
        : ratio < 0.85
            ? AppColors.warning
            : AppColors.error;

    return GlassCard(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.seatSelection,
        arguments: bus,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                route?.lineNumber ?? 'L?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route?.name ?? 'Unknown Route',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${route?.origin ?? '?'} → ${route?.destination ?? '?'}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                OccupancyBar(
                    booked: bus.bookedSeats, total: bus.totalSeats),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bus.departureTime,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              StatusChip(
                label: bus.isFull ? 'Full' : '${bus.availableSeats} left',
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Routes Tab ────────────────────────────────────────────────────────────

class _RoutesTab extends StatefulWidget {
  const _RoutesTab();

  @override
  State<_RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<_RoutesTab> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final routes = provider.routes
        .where((r) =>
            r.name.toLowerCase().contains(_search.toLowerCase()) ||
            r.origin.toLowerCase().contains(_search.toLowerCase()) ||
            r.destination.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bus Routes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(
                      hintText: 'Search routes, stops...',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: routes.isEmpty
                  ? const EmptyState(
                      icon: Icons.map_outlined,
                      title: 'No routes found',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: routes.length,
                      itemBuilder: (context, i) {
                        final route = routes[i];
                        final buses = provider.getBusesForRoute(route.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RouteCard(route: route, buses: buses),
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

class _RouteCard extends StatelessWidget {
  final BusRoute route;
  final List<Bus> buses;

  const _RouteCard({required this.route, required this.buses});

  @override
  Widget build(BuildContext context) {
    final availableBuses = buses.where((b) => !b.isFull).length;

    return GlassCard(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.routeSearch,
        arguments: route,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  route.lineNumber,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  route.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              StatusChip(
                label: '$availableBuses buses',
                color: availableBuses > 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(route.origin,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(width: 2, height: 16, color: AppColors.darkBorder),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AppColors.magenta),
              const SizedBox(width: 6),
              Text(route.destination,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: route.stops
                .take(4)
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.darkNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ))
                .toList(),
          ),
          if (route.standingAllowed) ...[
            const SizedBox(height: 8),
            const StatusChip(
              label: 'Standing available',
              color: AppColors.teal,
              icon: Icons.airline_seat_recline_extra_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── My Trips Tab ──────────────────────────────────────────────────────────

class _MyTripsTab extends StatelessWidget {
  const _MyTripsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final reservations = provider.myReservations
      ..sort((a, b) => b.reservedAt.compareTo(a.reservedAt));

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Trips',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: reservations.isEmpty
                  ? EmptyState(
                      icon: Icons.confirmation_num_outlined,
                      title: 'No trips yet',
                      subtitle: 'Your reservations will appear here',
                      action: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.routeSearch),
                        icon: const Icon(Icons.search),
                        label: const Text('Find a Bus'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: reservations.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReservationCard(reservation: reservations[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  Color get _statusColor {
    switch (reservation.status) {
      case ReservationStatus.confirmed:
        return AppColors.success;
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.cancelled:
        return AppColors.error;
      case ReservationStatus.boarded:
        return AppColors.teal;
      case ReservationStatus.noShow:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (reservation.status) {
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.boarded:
        return 'Boarded';
      case ReservationStatus.noShow:
        return 'No Show';
    }
  }

  void _showCancelDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Cancel Reservation?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Repeated cancellations may result in a suspension penalty.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.cancelReservation(reservation.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return GlassCard(
      onTap: reservation.isActive
          ? () => Navigator.pushNamed(
                context,
                AppRoutes.qrDisplay,
                arguments: reservation,
              )
          : null,
      borderColor:
          reservation.isActive ? AppColors.orange.withOpacity(0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${reservation.origin} → ${reservation.destination}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700),
                ),
              ),
              StatusChip(label: _statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('MMM d').format(reservation.departureDate)} at ${reservation.departureTime}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.event_seat_outlined,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                reservation.seatType == SeatType.standing
                    ? 'Standing'
                    : 'Seat ${reservation.seatNumber}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          if (reservation.isActive) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(context, provider),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (reservation.status == ReservationStatus.pending) {
                        provider.confirmReservation(reservation.id);
                      } else {
                        Navigator.pushNamed(context, AppRoutes.qrDisplay,
                            arguments: reservation);
                      }
                    },
                    icon: Icon(
                      reservation.status == ReservationStatus.pending
                          ? Icons.check_circle_outline
                          : Icons.qr_code_2_rounded,
                      size: 16,
                    ),
                    label: Text(
                      reservation.status == ReservationStatus.pending
                          ? 'Confirm'
                          : 'QR Code',
                    ),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── AI Chat Tab ───────────────────────────────────────────────────────────

class _AIChatTab extends StatefulWidget {
  const _AIChatTab();

  @override
  State<_AIChatTab> createState() => _AIChatTabState();
}

class _AIChatTabState extends State<_AIChatTab> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _loading = false;

  final List<String> _suggestions = [
    'Which bus to campus at 8am?',
    'Is Line L1 available now?',
    'What happens if I cancel?',
    'Predict peak hours tomorrow',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMsg(
      isUser: false,
      text:
          '👋 Hi! I\'m UniRide AI. Ask me about bus schedules, availability, or trip planning!',
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _ctrl.clear();

    final provider = context.read<AppProvider>();
    final gemma = context.read<GemmaService>();
    final user = provider.currentUser;

    setState(() {
      _messages.add(_ChatMsg(isUser: true, text: text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await gemma.sendMessage(text, role: user?.role);
      if (!mounted) return;
      setState(() => _messages.add(_ChatMsg(isUser: false, text: reply)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(const _ChatMsg(
            isUser: false,
            text: '⚠️ Could not reach AI backend. Check backend is running.',
            isError: true,
          )));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient:
                          LinearGradient(colors: [AppColors.teal, AppColors.blue]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UniRide AI',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Powered by Gemini',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return _TypingBubble();
                  }
                  return _messages[i];
                },
              ),
            ),

            // Quick suggestions (only when fresh)
            if (_messages.length <= 1)
              SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: _suggestions
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label:
                                  Text(s, style: const TextStyle(fontSize: 12)),
                              onPressed: () => _send(s),
                              backgroundColor: AppColors.darkCard,
                              side: const BorderSide(color: AppColors.orange),
                              labelStyle:
                                  const TextStyle(color: AppColors.orange),
                            ),
                          ))
                      .toList(),
                ),
              ),

            // Input bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      enabled: !_loading,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about buses, routes...',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : () => _send(_ctrl.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: _loading
                            ? const LinearGradient(colors: [
                                AppColors.darkBorder,
                                AppColors.darkBorder
                              ])
                            : AppColors.primaryGradient,
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

class _ChatMsg extends StatelessWidget {
  final bool isUser;
  final String text;
  final bool isError;

  const _ChatMsg({
    required this.isUser,
    required this.text,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [AppColors.teal, AppColors.blue]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser
                    ? null
                    : isError
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.darkCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isError
                            ? AppColors.error.withOpacity(0.3)
                            : AppColors.darkBorder),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.teal, AppColors.blue]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 15),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeOut(delay: Duration(milliseconds: i * 200))
                    .then()
                    .fadeIn(),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Profile Tab ───────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(user.email,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              StatusChip(label: user.role.name.toUpperCase(), color: AppColors.orange),
              if (user.studentId != null) ...[
                const SizedBox(height: 6),
                StatusChip(label: user.studentId!, color: AppColors.purple),
              ],
              if (user.isPenalized) ...[
                const SizedBox(height: 8),
                StatusChip(
                  label:
                      'Penalized until ${DateFormat('MMM d').format(user.penaltyUntil!)}',
                  color: AppColors.error,
                  icon: Icons.block_rounded,
                ),
              ],

              const SizedBox(height: 32),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Trips',
                      value: '${provider.myReservations.length}',
                      icon: Icons.confirmation_num_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Active',
                      value: '${provider.myActiveReservations.length}',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Cancels',
                      value:
                          '${user.cancellationCount}/${AppConstants.maxCancellationsBeforePenalty}',
                      icon: Icons.cancel_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _MenuItem(
                icon: Icons.calendar_today_outlined,
                label: 'My Schedule',
                onTap: () => Navigator.pushNamed(context, AppRoutes.schedule),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                trailing: provider.unreadNotifications.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${provider.unreadNotifications.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      )
                    : null,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                color: AppColors.error,
                onTap: () async {
                  await provider.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(color: c, fontWeight: FontWeight.w500))),
          trailing ??
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
