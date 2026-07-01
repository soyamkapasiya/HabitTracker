import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/habit.dart';
import 'widgets/spreadsheet_grid.dart';
import 'widgets/ios_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automated Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff13854e),
          primary: const Color(0xff13854e),
          secondary: const Color(0xfff43f5e),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainTabContainer(),
    );
  }
}

class MainTabContainer extends StatefulWidget {
  const MainTabContainer({Key? key}) : super(key: key);

  @override
  State<MainTabContainer> createState() => _MainTabContainerState();
}

class _MainTabContainerState extends State<MainTabContainer> {
  int _activeTabIndex = 0;
  List<Habit> _habits = [];
  bool _loading = true;

  // Date controls
  DateTime _currentMonthDate = DateTime.now();
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Align week start to Monday
    final day = _currentWeekStart.weekday;
    final diff = _currentWeekStart.day - day + (day == DateTime.sunday ? -6 : 1);
    _currentWeekStart = DateTime(_currentWeekStart.year, _currentWeekStart.month, diff);

    _loadHabits();
  }

  // Load habits from shared preferences
  Future<void> _loadHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? habitsJson = prefs.getString('habits_db');
      
      if (habitsJson != null) {
        final List<dynamic> decoded = json.decode(habitsJson);
        setState(() {
          _habits = decoded.map((item) => Habit.fromMap(item)).toList();
          _loading = false;
        });
      } else {
        // Seed default habits
        final seeded = Habit.getInitialHabits();
        setState(() {
          _habits = seeded;
          _loading = false;
        });
        await _saveHabits();
      }
    } catch (e) {
      // Fallback
      setState(() {
        _habits = Habit.getInitialHabits();
        _loading = false;
      });
    }
  }

  // Save habits to shared preferences
  Future<void> _saveHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMaps = _habits.map((h) => h.toMap()).toList();
      await prefs.setString('habits_db', json.encode(listMaps));
    } catch (_) {}
  }

  // Toggle habit done state
  void _toggleHabit(String habitId, String dateKey) {
    setState(() {
      _habits = _habits.map((habit) {
        if (habit.id == habitId) {
          final isDone = habit.done[dateKey] == true;
          final updatedDone = Map<String, bool>.from(habit.done);
          if (isDone) {
            updatedDone.remove(dateKey);
          } else {
            updatedDone[dateKey] = true;
          }
          return habit.copyWith(done: updatedDone);
        }
        return habit;
      }).toList();
    });
    _saveHabits();
  }

  // Add new habit
  void _addHabit(String name, String emoji, int categoryIdx, int goal, String desc) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final todayStr = Habit.formatDateKey(DateTime.now());
    
    setState(() {
      _habits.add(Habit(
        id: newId,
        name: name,
        categoryIndex: categoryIdx,
        description: desc,
        emoji: emoji.isEmpty ? '⭐' : emoji,
        goalDays: goal,
        createdAt: todayStr,
        done: {},
      ));
    });
    _saveHabits();
  }

  // Update existing habit
  void _updateHabit(String id, String name, String emoji, int categoryIdx, int goal, String desc) {
    setState(() {
      _habits = _habits.map((h) {
        if (h.id == id) {
          return h.copyWith(
            name: name,
            emoji: emoji,
            categoryIndex: categoryIdx,
            goalDays: goal,
            description: desc,
          );
        }
        return h;
      }).toList();
    });
    _saveHabits();
  }

  // Delete habit
  void _deleteHabit(String id) {
    setState(() {
      _habits.removeWhere((h) => h.id == id);
    });
    _saveHabits();
  }

  // Modal Dialog sheet for Adding / Editing Habits
  void _openHabitFormDialog([Habit? habit]) {
    final isEditing = habit != null;
    String formName = habit?.name ?? '';
    String formEmoji = habit?.emoji ?? '⏰';
    int formCategory = habit?.categoryIndex ?? 0;
    int formGoal = habit?.goalDays ?? 30;
    String formDesc = habit?.description ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'MODIFY HABIT DETAILS' : 'ESTABLISH NEW HABIT',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff13854e),
                            letterSpacing: 1.2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Name
                    const Text(
                      'HABIT NAME',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: formName)..selection = TextSelection.collapsed(offset: formName.length),
                      onChanged: (val) => formName = val,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Wake up at 05:00',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: formDesc),
                      onChanged: (val) => formDesc = val,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Describe details of the routine...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Goal Days
                    const Text(
                      'MONTHLY TARGET (GOAL DAYS)',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: TextEditingController(text: formGoal.toString()),
                      onChanged: (val) => formGoal = int.tryParse(val) ?? 30,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Emoji Pick
                    const Text(
                      'EMOJI / BADGE CHAR',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xfff1f5f9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(formEmoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: formEmoji),
                            onChanged: (val) {
                              setModalState(() {
                                formEmoji = val.trim();
                              });
                            },
                            maxLength: 2,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick select Emojis row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: ['⏰', '💪', '🔞', '📖', '💰', '🎯', '🚫', '🌿', '📒', '🚿', '💧', '🏃'].map((emoji) {
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              formEmoji = emoji;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: formEmoji == emoji ? const Color(0xffe2e8f0) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: formEmoji == emoji ? const Color(0xffcbd5e1) : Colors.transparent),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Category allocation picker
                    const Text(
                      'CATEGORY ALLOCATION',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(categories.length, (idx) {
                        final cat = categories[idx];
                        final isSel = formCategory == idx;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              formCategory = idx;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, py: 6),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xffe2f0d9) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? const Color(0xff13854e) : const Color(0xffcbd5e1),
                              ),
                            ),
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSel ? const Color(0xff13854e) : const Color(0xff64748b),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Submit Cancel
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff13854e),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (formName.trim().isEmpty) return;
                              if (isEditing) {
                                _updateHabit(habit.id, formName, formEmoji, formCategory, formGoal, formDesc);
                              } else {
                                _addHabit(formName, formEmoji, formCategory, formGoal, formDesc);
                              }
                              Navigator.pop(context);
                            },
                            child: Text(isEditing ? 'Save Changes' : 'Establish', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Habit Manager view tab body
  Widget _buildManageView() {
    return Container(
      color: const Color(0xfff6f8fa),
      child: Column(
        children: [
          // Subheader
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xffe2e8f0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HABIT MANAGER',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.black, color: Color(0xff1e293b)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Configure habit goals and parameters.',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    )
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff13854e),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => _openHabitFormDialog(),
                  icon: const Icon(Icons.plus_one, size: 14),
                  label: const Text('Establish', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          // Habits config cards list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                final checkins = habit.done.values.where((v) => v == true).length;
                final streaks = habit.calculateStreaks();
                final currentStreak = streaks['current'] ?? 0;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xffe2e8f0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff1f5f9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(habit.emoji, style: const TextStyle(fontSize: 18)),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.name,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.black, color: Color(0xff1e293b)),
                                    ),
                                    Text(
                                      'Target Goal: ${habit.goalDays} Days / month'.toUpperCase(),
                                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'monospace'),
                                    )
                                  ],
                                )
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xfff1f5f9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                categories[habit.categoryIndex].name.toUpperCase(),
                                style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xff64748b)),
                              ),
                            )
                          ],
                        ),

                        if (habit.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xfff8fafc),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xfff1f5f9)),
                            ),
                            child: Text(
                              habit.description,
                              style: const TextStyle(fontSize: 10, color: Color(0xff475569)),
                            ),
                          )
                        ],

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Completions: $checkins days',
                              style: const TextStyle(fontSize: 10, color: Color(0xff64748b), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            Text(
                              '🔥 Streak: $currentStreak days',
                              style: const TextStyle(fontSize: 10, color: Color(0xff13854e), fontWeight: FontWeight.black, fontFamily: 'monospace'),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Divider(height: 1),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => _openHabitFormDialog(habit),
                              icon: const Icon(Icons.edit, size: 10),
                              label: const Text('Edit', style: TextStyle(fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                foregroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: const BorderSide(color: Colors.redAccent),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Habit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    content: Text('Are you sure you want to remove "${habit.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteHabit(habit.id);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete, size: 10),
                              label: const Text('Delete', style: TextStyle(fontSize: 10)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xff13854e),
          ),
        ),
      );
    }

    final double bottomInset = MediaQuery.of(context).padding.bottom;

    // Select body widget based on active index
    Widget bodyView;
    if (_activeTabIndex == 0) {
      bodyView = SpreadsheetGrid(
        habits: _habits,
        onToggleDone: _toggleHabit,
        currentMonthDate: _currentMonthDate,
        onMonthChanged: (newMonth) {
          setState(() {
            _currentMonthDate = newMonth;
          });
        },
      );
    } else if (_activeTabIndex == 1) {
      bodyView = IosDashboard(
        habits: _habits,
        onToggleDone: _toggleHabit,
        currentWeekStart: _currentWeekStart,
        onWeekChanged: (newWeekStart) {
          setState(() {
            _currentWeekStart = newWeekStart;
          });
        },
      );
    } else {
      bodyView = _buildManageView();
    }

    return Scaffold(
      backgroundColor: const Color(0xfff6f8fa),
      
      // Header
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: Color(0xffcbd5e1), width: 0.5)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xff13854e),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text('田', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Habits',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.black, color: Color(0xff0f172a), height: 1.0),
                ),
                Text(
                  'AUTOMATED DASHBOARD',
                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
                )
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xff13854e), size: 24),
            onPressed: () => _openHabitFormDialog(),
          ),
        ],
      ),

      body: SafeArea(
        bottom: false,
        child: bodyView,
      ),

      // Custom Bottom iOS Tab bar
      bottomNavigationBar: Container(
        height: 60 + bottomInset,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xffe2e8f0), width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 4,
              offset: Offset(0, -2),
            )
          ],
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 1: Grid
            _buildTabItem(
              index: 0,
              icon: Icons.table_chart,
              label: 'Grid',
            ),
            // Tab 2: Dashboard
            _buildTabItem(
              index: 1,
              icon: Icons.dashboard,
              label: 'Dashboard',
            ),
            // Tab 3: Configure
            _buildTabItem(
              index: 2,
              icon: Icons.settings,
              label: 'Configure',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeTabIndex == index;
    final activeColor = isSelected ? const Color(0xff13854e) : const Color(0xff94a3b8);

    return InkWell(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: activeColor, size: 20),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: activeColor,
                letterSpacing: 0.8,
              ),
            )
          ],
        ),
      ),
    );
  }
}
