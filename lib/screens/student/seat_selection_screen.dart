import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/bus_model.dart';
import '../../models/reservation_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _selectedSeat;
  SeatType _seatType = SeatType.seated;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {
        _seatType =
            _tabCtrl.index == 0 ? SeatType.seated : SeatType.standing;
        _selectedSeat = null;
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bus = ModalRoute.of(context)!.settings.arguments as Bus;
    final provider = context.watch<AppProvider>();
    final route = provider.getRouteById(bus.routeId);
    final takenSeats = provider.getTakenSeats(bus.id);

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: UniRideAppBar(
        title: 'Select Seat',
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StatusChip(
                label: bus.isFull ? 'Full' : '${bus.availableSeats} left',
                color:
                    bus.isFull ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bus info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
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
                        '${route?.origin ?? '?'} → ${route?.destination ?? '?'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Departure: ${bus.departureTime} • ${bus.plateNumber}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          if (bus.standingAllowed)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [
                  Tab(text: 'Seated'),
                  Tab(text: 'Standing'),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: AppColors.darkBorder, label: 'Available'),
                const SizedBox(width: 16),
                _LegendItem(color: AppColors.error, label: 'Taken'),
                const SizedBox(width: 16),
                _LegendItem(color: AppColors.orange, label: 'Selected'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Seat grid / standing section
          Expanded(
            child: bus.standingAllowed
                ? TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _SeatedGrid(
                        bus: bus,
                        takenSeats: takenSeats,
                        selectedSeat: _selectedSeat,
                        onSelect: (s) =>
                            setState(() => _selectedSeat = s),
                      ),
                      _StandingSection(
                        bus: bus,
                        selectedSeat: _selectedSeat,
                        onSelect: (s) =>
                            setState(() => _selectedSeat = s),
                      ),
                    ],
                  )
                : _SeatedGrid(
                    bus: bus,
                    takenSeats: takenSeats,
                    selectedSeat: _selectedSeat,
                    onSelect: (s) =>
                        setState(() => _selectedSeat = s),
                  ),
          ),

          // Bottom action
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedSeat != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_seat_rounded,
                            color: AppColors.orange, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _seatType == SeatType.standing
                              ? 'Standing spot selected'
                              : 'Seat $_selectedSeat selected',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                GradientButton(
                  label: 'Reserve This Seat',
                  onPressed: _selectedSeat == null || _isLoading
                      ? null
                      : () => _reserve(context, bus),
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reserve(BuildContext context, Bus bus) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Confirm Reservation',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmRow(
              label: 'Seat',
              value: _seatType == SeatType.standing
                  ? 'Standing'
                  : _selectedSeat!,
            ),
            _ConfirmRow(label: 'Departure', value: bus.departureTime),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Repeated cancellations may result in penalties.',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();
    final error = await provider.createReservation(
      busId: bus.id,
      seatNumber: _selectedSeat!,
      seatType: _seatType,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Show success and offer to confirm
      final reserve = provider.myActiveReservations.lastOrNull;
      if (reserve != null) {
        await provider.confirmReservation(reserve.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Reservation confirmed!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View QR',
            onPressed: () {
              final r = provider.myActiveReservations.lastOrNull;
              if (r != null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.qrDisplay,
                  arguments: r,
                );
              }
            },
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _SeatedGrid extends StatelessWidget {
  final Bus bus;
  final List<String> takenSeats;
  final String? selectedSeat;
  final ValueChanged<String> onSelect;

  const _SeatedGrid({
    required this.bus,
    required this.takenSeats,
    required this.selectedSeat,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Driver row indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_bus_rounded,
                        color: AppColors.textMuted, size: 16),
                    SizedBox(width: 8),
                    Text('Driver',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seat grid (4 per row: 2 + aisle + 2)
          ...List.generate(
            (bus.totalSeats / 4).ceil(),
            (row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSeat('${row * 4 + 1}A', takenSeats, selectedSeat, onSelect),
                    const SizedBox(width: 6),
                    _buildSeat('${row * 4 + 1}B', takenSeats, selectedSeat, onSelect),
                    const SizedBox(width: 20),
                    _buildSeat('${row * 4 + 1}C', takenSeats, selectedSeat, onSelect),
                    const SizedBox(width: 6),
                    _buildSeat('${row * 4 + 1}D', takenSeats, selectedSeat, onSelect),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(String seatId, List<String> taken, String? selected,
      ValueChanged<String> onSelect) {
    final isTaken = taken.contains(seatId);
    final isSelected = selected == seatId;

    return GestureDetector(
      onTap: isTaken ? null : () => onSelect(seatId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected
              ? null
              : isTaken
                  ? AppColors.error.withOpacity(0.3)
                  : AppColors.darkCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isTaken
                    ? AppColors.error.withOpacity(0.5)
                    : AppColors.darkBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.4),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTaken
                  ? Icons.person_rounded
                  : Icons.event_seat_rounded,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : isTaken
                      ? AppColors.error
                      : AppColors.textMuted,
            ),
            Text(
              seatId,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isTaken
                        ? AppColors.error.withOpacity(0.7)
                        : AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingSection extends StatelessWidget {
  final Bus bus;
  final String? selectedSeat;
  final ValueChanged<String> onSelect;

  const _StandingSection({
    required this.bus,
    required this.selectedSeat,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final available = bus.availableStanding;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                const Icon(Icons.airline_seat_recline_extra_rounded,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  '$available standing spots',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${bus.standingBooked}/${bus.maxStanding} occupied',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                OccupancyBar(
                  booked: bus.standingBooked,
                  total: bus.maxStanding,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (available > 0)
            GradientButton(
              label: 'Reserve Standing Spot',
              onPressed: () => onSelect('STAND'),
              gradient: AppColors.purpleGradient,
            )
          else
            const StatusChip(
              label: 'No standing spots available',
              color: AppColors.error,
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
