import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/bus_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  final List<String> _timeFilters = [
    'All',
    'Morning (6-9)',
    'Midday (11-14)',
    'Evening (16-20)',
  ];
  String _timeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final preselectedRoute =
        ModalRoute.of(context)?.settings.arguments as BusRoute?;

    // Filter buses
    final buses = provider.buses.where((b) {
      final route = provider.getRouteById(b.routeId);
      if (route == null || !b.isActive) return false;

      final searchMatch = _search.isEmpty ||
          route.name.toLowerCase().contains(_search.toLowerCase()) ||
          route.origin.toLowerCase().contains(_search.toLowerCase()) ||
          route.destination
              .toLowerCase()
              .contains(_search.toLowerCase());

      if (preselectedRoute != null && b.routeId != preselectedRoute.id) {
        return false;
      }

      bool timeMatch = true;
      if (_timeFilter != 'All') {
        final hour =
            int.tryParse(b.departureTime.split(':').first) ?? 0;
        timeMatch = _timeFilter == 'Morning (6-9)'
            ? hour >= 6 && hour < 9
            : _timeFilter == 'Midday (11-14)'
                ? hour >= 11 && hour < 14
                : hour >= 16 && hour < 20;
      }

      return searchMatch && timeMatch;
    }).toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: UniRideAppBar(
        title: preselectedRoute?.name ?? 'Find a Bus',
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _timeFilters.map((f) {
                      final isSelected = _timeFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _timeFilter = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Bus list
          Expanded(
            child: buses.isEmpty
                ? EmptyState(
                    icon: Icons.directions_bus_outlined,
                    title: 'No buses found',
                    subtitle: 'Try different filters or request an extra bus',
                    action: ElevatedButton.icon(
                      onPressed: () => _showExtraBusDialog(context, provider),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Request Extra Bus'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: buses.length,
                    itemBuilder: (context, i) {
                      final bus = buses[i];
                      final route = provider.getRouteById(bus.routeId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BusListCard(bus: bus, route: route),
                      );
                    },
                  ),
          ),

          // Extra bus request button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showExtraBusDialog(context, provider),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Request Extra Bus'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.magenta,
                side: const BorderSide(color: AppColors.magenta),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExtraBusDialog(BuildContext context, AppProvider provider) {
    final routes = provider.routes;
    String? selectedRouteId =
        routes.isNotEmpty ? routes.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Request Extra Bus',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'When 15+ students request an extra bus for the same destination, admins will be notified.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (routes.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedRouteId,
                dropdownColor: AppColors.darkCard,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Route',
                ),
                items: routes
                    .map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name),
                        ))
                    .toList(),
                onChanged: (v) => selectedRouteId = v,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedRouteId == null) return;
              final route = provider.getRouteById(selectedRouteId!);
              await provider.requestExtraBus(
                routeId: selectedRouteId!,
                destination: route?.destination ?? 'Campus',
                date: DateTime.now(),
                time: '08:00',
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Extra bus requested!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}

class _BusListCard extends StatelessWidget {
  final Bus bus;
  final BusRoute? route;

  const _BusListCard({required this.bus, this.route});

  @override
  Widget build(BuildContext context) {
    final ratio =
        bus.totalSeats > 0 ? bus.bookedSeats / bus.totalSeats : 0.0;
    final statusColor = ratio < 0.5
        ? AppColors.success
        : ratio < 0.85
            ? AppColors.warning
            : AppColors.error;

    return GlassCard(
      onTap: bus.isFull
          ? null
          : () => Navigator.pushNamed(
                context,
                AppRoutes.seatSelection,
                arguments: bus,
              ),
      borderColor: bus.isFull ? null : AppColors.darkBorder,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: bus.isFull
                      ? const LinearGradient(
                          colors: [AppColors.textMuted, AppColors.textMuted])
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    route?.lineNumber ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
                      route?.name ?? 'Unknown',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${route?.origin ?? '?'} → ${route?.destination ?? '?'}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bus.departureTime,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  StatusChip(
                    label: bus.isFull
                        ? 'Full'
                        : '${bus.availableSeats} seats',
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          OccupancyBar(booked: bus.bookedSeats, total: bus.totalSeats),
          if (bus.standingAllowed && !bus.isFull) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.airline_seat_recline_extra_rounded,
                    size: 14, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(
                  '${bus.availableStanding} standing spots available',
                  style: const TextStyle(
                      color: AppColors.teal, fontSize: 12),
                ),
              ],
            ),
          ],
          if (bus.isFull) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Request extra bus
                },
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Request Extra Bus',
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.magenta,
                  side: const BorderSide(color: AppColors.magenta),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
