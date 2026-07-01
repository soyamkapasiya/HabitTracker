import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import 'donut_chart.dart';

class IosDashboard extends StatefulWidget {
  final List<Habit> habits;
  final Function(String habitId, String dateKey) onToggleDone;
  final DateTime currentWeekStart;
  final Function(DateTime newWeekStart) onWeekChanged;

  const IosDashboard({
    Key? key,
    required this.habits,
    required this.onToggleDone,
    required this.currentWeekStart,
    required this.onWeekChanged,
  }) : super(key: key);

  @override
  State<IosDashboard> createState() => _IosDashboardState();
}

class _IosDashboardState extends State<IosDashboard> {
  late String _selectedDateKey;

  @override
  void initState() {
    super.initState();
    _selectedDateKey = Habit.formatDateKey(DateTime.now());
  }

  // Get days list for the active week
  List<DateTime> _getWeekDays() {
    return List<DateTime>.generate(
      7,
      (i) => widget.currentWeekStart.add(Duration(days: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();

    // Verify if selected date is inside current week. If not, auto-sync.
    final hasSelectedDateInWeek = weekDays.any((d) => Habit.formatDateKey(d) == _selectedDateKey);
    if (!hasSelectedDateInWeek && weekDays.isNotEmpty) {
      _selectedDateKey = Habit.formatDateKey(weekDays[0]);
    }

    // Calculate weekly completions stats
    int weeklyCompleted = 0;
    int weeklyPossible = widget.habits.length * 7;
    for (var day in weekDays) {
      final key = Habit.formatDateKey(day);
      for (var h in widget.habits) {
        if (h.done[key] == true) {
          weeklyCompleted++;
        }
      }
    }
    final double weeklyPct = weeklyPossible > 0 ? (weeklyCompleted / weeklyPossible * 100).roundToDouble() : 0.0;

    // Get selected day details
    final selectedDate = DateTime.tryParse(_selectedDateKey) ?? DateTime.now();
    int selectedCompletedCount = 0;
    for (var h in widget.habits) {
      if (h.done[_selectedDateKey] == true) {
        selectedCompletedCount++;
      }
    }
    final double selectedPct = widget.habits.isNotEmpty 
        ? (selectedCompletedCount / widget.habits.length * 100).roundToDouble() 
        : 0.0;

    final weekStartStr = DateFormat('MMM d').format(widget.currentWeekStart);
    final weekEndStr = DateFormat('MMM d').format(widget.currentWeekStart.add(const Duration(days: 6)));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xfffffafb), Color(0xfffaf5f6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 1. Navigation & Week Control Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffffe4e6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DASHBOARD NAVIGATION',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xfff43f5e),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfffff5f5),
                        foregroundColor: const Color(0xfff43f5e),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xffffe4e6)),
                        ),
                      ),
                      onPressed: () {
                        widget.onWeekChanged(widget.currentWeekStart.subtract(const Duration(days: 7)));
                      },
                      icon: const Icon(Icons.arrow_back, size: 12),
                      label: const Text('Prev', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Text(
                      '$weekStartStr - $weekEndStr'.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff334155),
                        fontFamily: 'monospace',
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfffff5f5),
                        foregroundColor: const Color(0xfff43f5e),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xffffe4e6)),
                        ),
                      ),
                      onPressed: () {
                        widget.onWeekChanged(widget.currentWeekStart.add(const Duration(days: 7)));
                      },
                      child: Row(
                        children: [
                          const Text('Next ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_forward, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xffffe4e6)),
                ),

                // Week Progress row
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WEEK COMPLETION',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xffec4899), fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$weeklyCompleted/$weeklyPossible Done',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xff1e293b)),
                        )
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: weeklyPct / 100,
                          backgroundColor: const Color(0xffffe4e6),
                          color: const Color(0xfff43f5e),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$weeklyPct%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xfff43f5e), fontFamily: 'monospace'),
                    )
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. iOS Calendar Day Strip
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffffe4e6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((day) {
                final key = Habit.formatDateKey(day);
                final isActive = key == _selectedDateKey;
                final dayInitial = DateFormat('E').format(day).substring(0, 3).toUpperCase();
                final dayNum = day.day.toString();

                // Has completions check
                int completions = 0;
                for (var h in widget.habits) {
                  if (h.done[key] == true) completions++;
                }
                final double dayPct = widget.habits.isNotEmpty ? completions / widget.habits.length : 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDateKey = key;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: isActive
                              ? const LinearGradient(
                                  colors: [Color(0xfff43f5e), Color(0xffec4899)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayInitial,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : const Color(0xff94a3b8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayNum,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: isActive ? Colors.white : const Color(0xff334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Dot indicator
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive 
                                    ? Colors.white 
                                    : (dayPct > 0 ? const Color(0xfff43f5e) : Colors.transparent),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Active Selected Day card layout
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffffe4e6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Column(
              children: [
                // Header banner
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xffffe4e6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE').format(selectedDate).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff9f1239),
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xfff43f5e),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                // Donut Chart Progress display
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: DonutChart(
                      percentage: selectedPct,
                      size: 64,
                      strokeWidth: 6,
                      variant: 'rose',
                    ),
                  ),
                ),

                // Checklist Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "TODAY'S ROUTINE",
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff94a3b8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Habits checklist builder
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
                  itemCount: widget.habits.length,
                  itemBuilder: (context, index) {
                    final habit = widget.habits[index];
                    final isChecked = habit.done[_selectedDateKey] == true;
                    final streaks = habit.calculateStreaks();
                    final streakVal = streaks['current'] ?? 0;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isChecked ? const Color(0xfff1f5f9) : const Color(0xffffe4e6).withOpacity(0.6),
                        ),
                      ),
                      color: isChecked ? const Color(0xfff8fafc).withOpacity(0.5) : Colors.white,
                      child: InkWell(
                        onTap: () {
                          widget.onToggleDone(habit.id, _selectedDateKey);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // Avatar circle
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isChecked ? const Color(0xffe2e8f0) : const Color(0xfffff5f5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  habit.emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Text items
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isChecked ? FontWeight.normal : FontWeight.bold,
                                        color: isChecked ? const Color(0xff94a3b8) : const Color(0xff1e293b),
                                        decoration: isChecked ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (streakVal > 0 && !isChecked) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffaf5ff),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🔥 ', style: TextStyle(fontSize: 8)),
                                            Text(
                                              '${streakVal}d streak'.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 7,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xffe040fb),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              ),

                              // Circular Radio Selector
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: isChecked 
                                      ? null 
                                      : Border.all(color: const Color(0xffcbd5e1), width: 1.5),
                                  gradient: isChecked
                                      ? const LinearGradient(
                                          colors: [Color(0xfff43f5e), Color(0xffec4899)],
                                        )
                                      : null,
                                ),
                                child: isChecked
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : null,
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
