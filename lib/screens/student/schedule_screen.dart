import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final schedules = provider.schedules;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: UniRideAppBar(
        title: 'My Schedule',
        actions: [
          IconButton(
            onPressed: () => _showAddScheduleDialog(context, provider),
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.darkCard,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              borderColor: AppColors.teal.withOpacity(0.4),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppColors.teal, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your schedule helps the AI recommend the best bus times for your classes.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (schedules.isEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'No classes added yet',
                subtitle: 'Add your class schedule for smarter bus recommendations',
                action: ElevatedButton.icon(
                  onPressed: () =>
                      _showAddScheduleDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Class'),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final dayIdx in List.generate(7, (i) => i + 1))
                    ...() {
                      final daySchedules = schedules
                          .where((s) => s.weekdays.contains(dayIdx))
                          .toList()
                        ..sort((a, b) => a.startTime.compareTo(b.startTime));

                      if (daySchedules.isEmpty) return <Widget>[];

                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _days[dayIdx - 1],
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        ...daySchedules.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ScheduleCard(
                                schedule: s,
                                onDelete: () =>
                                    provider.deleteSchedule(s.id),
                              ),
                            )),
                      ];
                    }(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, AppProvider provider) {
    final courseCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '08:00');
    final endCtrl = TextEditingController(text: '10:00');
    List<int> selectedDays = [1]; // Monday by default
    String color = '#8B5CF6';

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          title: const Text('Add Class',
              style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: courseCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Course Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Building / Room'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            const InputDecoration(labelText: 'Start'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            const InputDecoration(labelText: 'End'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Days',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: List.generate(
                    6,
                    (i) {
                      final dayNum = i + 1;
                      final selected = selectedDays.contains(dayNum);
                      return GestureDetector(
                        onTap: () => setDialogState(() {
                          if (selected) {
                            selectedDays.remove(dayNum);
                          } else {
                            selectedDays.add(dayNum);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? AppColors.primaryGradient
                                : null,
                            color:
                                selected ? null : AppColors.darkNavy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            days[i],
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
                if (courseCtrl.text.isEmpty) return;
                final user = provider.currentUser!;
                final schedule = ClassSchedule(
                  userId: user.id,
                  courseName: courseCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  weekdays: selectedDays,
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                  color: color,
                );
                await provider.saveSchedule(schedule);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ClassSchedule schedule;
  final VoidCallback onDelete;

  const _ScheduleCard({required this.schedule, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Parse color
    Color cardColor = AppColors.purple;
    try {
      final hex = schedule.color.replaceAll('#', '');
      cardColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return GlassCard(
      borderColor: cardColor.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.courseName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      schedule.location,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${schedule.startTime} - ${schedule.endTime}',
                style: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
