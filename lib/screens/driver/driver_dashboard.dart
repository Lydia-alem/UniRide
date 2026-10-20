import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/reservation_model.dart';
import '../../models/bus_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const _DriverHomeTab(),
        const _ScannerTab(),
        const _DriverAITab(),
        const _DriverProfileTab(),
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
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Scanner',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
              label: 'AI Help',
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

// ─── Driver Home ────────────────────────────────────────────────────────────

class _DriverHomeTab extends StatelessWidget {
  const _DriverHomeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;

    // Get today's buses for this driver
    final today = DateTime.now();
    final myBuses = provider.buses
        .where((b) =>
            b.driverId == user.id &&
            b.departureDate.day == today.day &&
            b.isActive)
        .toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Dashboard',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          user.name,
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                // Today's date
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(today),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _DriverStat(
                        label: 'Trips Today',
                        value: '${myBuses.length}',
                        icon: Icons.route_rounded,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DriverStat(
                        label: 'Total Passengers',
                        value: '${myBuses.fold(0, (s, b) => s + b.bookedSeats)}',
                        icon: Icons.people_rounded,
                        color: AppColors.magenta,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DriverStat(
                        label: 'Boarding Rate',
                        value: myBuses.isEmpty
                            ? 'N/A'
                            : '${((myBuses.fold(0, (s, b) => s + b.bookedSeats) / myBuses.fold(1, (s, b) => s + b.totalSeats)) * 100).toStringAsFixed(0)}%',
                        icon: Icons.bar_chart_rounded,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                const SectionHeader(title: "Today's Routes"),
                const SizedBox(height: 12),

                if (myBuses.isEmpty)
                  const EmptyState(
                    icon: Icons.directions_bus_outlined,
                    title: 'No routes scheduled today',
                    subtitle: 'Check back tomorrow',
                  )
                else
                  ...myBuses.asMap().entries.map((entry) {
                    final bus = entry.value;
                    final route = provider.getRouteById(bus.routeId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DriverBusCard(bus: bus, route: route),
                    ).animate().fadeIn(
                          delay: Duration(
                              milliseconds: 200 + entry.key * 100));
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DriverStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DriverBusCard extends StatefulWidget {
  final Bus bus;
  final BusRoute? route;

  const _DriverBusCard({required this.bus, this.route});

  @override
  State<_DriverBusCard> createState() => _DriverBusCardState();
}

class _DriverBusCardState extends State<_DriverBusCard> {
  bool _expanded = false;

  String _statusLabel(String s) {
    switch (s) {
      case 'scheduled':
        return 'Scheduled';
      case 'boarding':
        return 'Boarding';
      case 'en_route':
        return 'En Route';
      case 'arrived':
        return 'Arrived';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'scheduled':
        return AppColors.textSecondary;
      case 'boarding':
        return AppColors.warning;
      case 'en_route':
        return AppColors.blue;
      case 'arrived':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final reservations = provider.reservations
        .where((r) => r.busId == widget.bus.id && r.isActive)
        .toList();

    return GlassCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.route?.lineNumber ?? 'L?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.route?.name ?? 'Route',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.bus.departureTime} — ${widget.bus.plateNumber}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: _statusLabel(widget.bus.status),
                color: _statusColor(widget.bus.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OccupancyBar(
            booked: widget.bus.bookedSeats,
            total: widget.bus.totalSeats,
          ),

          // Status update buttons
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in [
                  'scheduled',
                  'boarding',
                  'en_route',
                  'arrived'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          provider.updateBusStatus(widget.bus.id, status),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.bus.status == status
                              ? _statusColor(status).withOpacity(0.2)
                              : AppColors.darkNavy,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.bus.status == status
                                ? _statusColor(status)
                                : AppColors.darkBorder,
                          ),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: widget.bus.status == status
                                ? _statusColor(status)
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (_expanded && reservations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Passenger List (${reservations.length})',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ...reservations.map((r) {
              final u = provider.getUserById(r.userId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.darkNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          r.seatNumber.substring(0, 1),
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        u?.name ?? 'Unknown',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ),
                    StatusChip(
                      label: r.status == ReservationStatus.boarded
                          ? 'Boarded'
                          : r.seatNumber,
                      color: r.status == ReservationStatus.boarded
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── QR Scanner Tab ─────────────────────────────────────────────────────────

class _ScannerTab extends StatefulWidget {
  const _ScannerTab();

  @override
  State<_ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<_ScannerTab> {
  String? _result;
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Scanner',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Scan passenger boarding passes',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            // Scanner placeholder (mobile_scanner in real device)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.orange.withOpacity(0.5), width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Scanner corners
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _ScannerCorner(position: 'tl'),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _ScannerCorner(position: 'tr'),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: _ScannerCorner(position: 'bl'),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: _ScannerCorner(position: 'br'),
                        ),
                        const Center(
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 80,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2000.ms, color: AppColors.orange.withOpacity(0.3)),

                  const SizedBox(height: 24),

                  const Text(
                    'Point camera at passenger QR code',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 32),

                  // Manual input option
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: GradientButton(
                      label: 'Simulate Scan',
                      onPressed: () => _simulateScan(context),
                    ),
                  ),

                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (_success ? AppColors.success : AppColors.error)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_success
                                  ? AppColors.success
                                  : AppColors.error)
                              .withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _success
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _success
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _result!,
                              style: TextStyle(
                                color: _success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulateScan(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final reservations = provider.reservations
        .where((r) => r.status == ReservationStatus.confirmed)
        .toList();

    if (reservations.isEmpty) {
      setState(() {
        _result = 'No confirmed reservations to scan';
        _success = false;
      });
      return;
    }

    // Simulate scanning the first confirmed reservation
    final res = reservations.first;
    await provider.markBoarded(res.id);
    final user = provider.getUserById(res.userId);

    setState(() {
      _result = '✓ ${user?.name ?? 'Passenger'} — Seat ${res.seatNumber} validated!';
      _success = true;
    });
  }
}

class _ScannerCorner extends StatelessWidget {
  final String position;

  const _ScannerCorner({required this.position});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _CornerPainter(position: position),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final String position;

  _CornerPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    switch (position) {
      case 'tl':
        canvas.drawLine(Offset(0, h), const Offset(0, 0), paint);
        canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
      case 'tr':
        canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
        canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      case 'bl':
        canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
        canvas.drawLine(Offset(0, h), Offset(w, h), paint);
      case 'br':
        canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
        canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Driver AI Tab ──────────────────────────────────────────────────────────

class _DriverAITab extends StatefulWidget {
  const _DriverAITab();

  @override
  State<_DriverAITab> createState() => _DriverAITabState();
}

class _DriverAITabState extends State<_DriverAITab> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          '🚌 Hello driver! I can help you with route information, passenger management tips, and trip planning. What do you need?',
    }
  ];
  bool _loading = false;

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _messages.add({
        'role': 'ai',
        'text': 'I can help with that! For detailed route info and passenger management, check your dashboard. The AI backend provides real-time assistance when connected.',
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
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Driver AI Assistant',
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
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('AI is thinking...',
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
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? AppColors.primaryGradient
                              : null,
                          color:
                              isUser ? null : AppColors.darkCard,
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
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                        hintText: 'Ask a question...',
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
                        gradient: AppColors.primaryGradient,
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

// ─── Driver Profile ──────────────────────────────────────────────────────────

class _DriverProfileTab extends StatelessWidget {
  const _DriverProfileTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
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
              const SizedBox(height: 12),
              Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(user.email,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const StatusChip(
                label: 'DRIVER',
                color: AppColors.blue,
              ),
              const SizedBox(height: 32),
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
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
