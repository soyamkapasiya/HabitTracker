import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';

class SpreadsheetGrid extends StatefulWidget {
  final List<Habit> habits;
  final Function(String habitId, String dateKey) onToggleDone;
  final DateTime currentMonthDate;
  final Function(DateTime newMonth) onMonthChanged;

  const SpreadsheetGrid({
    Key? key,
    required this.habits,
    required this.onToggleDone,
    required this.currentMonthDate,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  State<SpreadsheetGrid> createState() => _SpreadsheetGridState();
}

class _SpreadsheetGridState extends State<SpreadsheetGrid> {
  late ScrollController _leftVerticalController;
  late ScrollController _rightVerticalController;
  bool _isSyncingLeft = false;
  bool _isSyncingRight = false;

  @override
  void initState() {
    super.initState();
    _leftVerticalController = ScrollController();
    _rightVerticalController = ScrollController();

    // Synchronize scrolls
    _leftVerticalController.addListener(() {
      if (_isSyncingRight) return;
      _isSyncingLeft = true;
      if (_rightVerticalController.hasClients) {
        _rightVerticalController.jumpTo(_leftVerticalController.offset);
      }
      _isSyncingLeft = false;
    });

    _rightVerticalController.addListener(() {
      if (_isSyncingLeft) return;
      _isSyncingRight = true;
      if (_leftVerticalController.hasClients) {
        _leftVerticalController.jumpTo(_rightVerticalController.offset);
      }
      _isSyncingRight = false;
    });
  }

  @override
  void dispose() {
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    super.dispose();
  }

  // Get Excel letter (0 -> A, 1 -> B, etc.)
  String _getExcelLetter(int index) {
    String label = '';
    int temp = index;
    while (temp >= 0) {
      label = String.fromCharCode((temp % 26) + 65) + label;
      temp = (temp / 26).floor() - 1;
    }
    return label;
  }

  // Calculate month dates list
  List<DateTime> _getDaysInMonth() {
    final year = widget.currentMonthDate.year;
    final month = widget.currentMonthDate.month;
    final totalDays = DateTime(year, month + 1, 0).day;
    
    return List<DateTime>.generate(
      totalDays,
      (i) => DateTime(year, month, i + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final totalColumns = days.length + 5; // A, B, Days..., Goal, Act, Progress

    // Calculate overall statistics
    int totalGoal = 0;
    int totalActual = 0;
    final year = widget.currentMonthDate.year;
    final month = widget.currentMonthDate.month;

    for (var h in widget.habits) {
      totalGoal += h.goalDays;
      totalActual += h.done.keys.where((k) {
        final d = DateTime.tryParse(k);
        return d != null && d.year == year && d.month == month && h.done[k] == true;
      }).length;
    }

    final double overallPct = totalGoal > 0 ? (totalActual / totalGoal * 100).roundToDouble() : 0.0;

    return Column(
      children: [
        // Grid Formula Bar / Month Controls
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffe2e8f0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0a000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Month Picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE MONTH',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff94a3b8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.chevron_left, size: 20, color: Color(0xff64748b)),
                        onPressed: () {
                          widget.onMonthChanged(
                            DateTime(widget.currentMonthDate.year, widget.currentMonthDate.month - 1),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM yyyy').format(widget.currentMonthDate).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff1e293b),
                          letterSpacing: 1.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.chevron_right, size: 20, color: Color(0xff64748b)),
                        onPressed: () {
                          widget.onMonthChanged(
                            DateTime(widget.currentMonthDate.year, widget.currentMonthDate.month + 1),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),
              
              // Progress block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, py: 6),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fafc),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GRID PROGRESS',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff94a3b8),
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '$overallPct%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.black,
                            color: Color(0xff13854e),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: overallPct / 100,
                          backgroundColor: const Color(0xffe2e8f0),
                          color: const Color(0xff22c55e),
                          minHeight: 6,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),

        // Spreadsheet Core
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffcbd5e1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Row(
                children: [
                  
                  // 1. FREEZE PANEL (Sticky Column A & B)
                  SizedBox(
                    width: 142, // A: 32, B: 110
                    child: Column(
                      children: [
                        // Headers stack (Excel Column Letter, Weeks Row, Days, Names)
                        _buildLeftHeaderCell(
                          height: 24,
                          text: _getExcelLetter(0),
                          textB: _getExcelLetter(1),
                          isLetter: true,
                        ),
                        _buildLeftHeaderCell(height: 24, text: '', textB: ''),
                        _buildLeftHeaderCell(height: 28, text: '', textB: ''),
                        _buildLeftHeaderCell(
                          height: 28,
                          text: '',
                          textB: 'My Habits',
                          fontWeightB: FontWeight.bold,
                          color: const Color(0xfff8fafc),
                        ),
                        
                        // Frozen Habits rows list
                        Expanded(
                          child: ListView.builder(
                            controller: _leftVerticalController,
                            itemCount: widget.habits.length + 3, // Habits + 3 stat rows
                            itemExtent: 32,
                            itemBuilder: (context, index) {
                              if (index < widget.habits.length) {
                                final habit = widget.habits[index];
                                return _buildLeftRowCell(
                                  rowIndex: index + 1,
                                  habitEmoji: habit.emoji,
                                  habitName: habit.name,
                                );
                              } else {
                                // Bottom formula stats labels
                                final statIndex = index - widget.habits.length;
                                const statLabels = [
                                  'Progress in %',
                                  'Completed',
                                  'Remaining',
                                ];
                                const statSigmas = ['Σ', '✓', '✗'];
                                return _buildLeftStatCell(
                                  sigma: statSigmas[statIndex],
                                  label: statLabels[statIndex],
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Thick Divider
                  Container(width: 1, color: const Color(0xffcbd5e1)),

                  // 2. SCROLLABLE DATA BODY
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        // Width: (Days count * 36) + Goal (44) + Act (44) + Progress (120)
                        width: (days.length * 36) + 44.0 + 44.0 + 120.0,
                        child: Column(
                          children: [
                            
                            // Headers Row 1: Excel Letters
                            Row(
                              children: [
                                ...List.generate(days.length, (idx) {
                                  return _buildHeaderCell(
                                    width: 36,
                                    height: 24,
                                    text: _getExcelLetter(idx + 2),
                                    isLetter: true,
                                  );
                                }),
                                _buildHeaderCell(width: 44, height: 24, text: _getExcelLetter(days.length + 2), isLetter: true),
                                _buildHeaderCell(width: 44, height: 24, text: _getExcelLetter(days.length + 3), isLetter: true),
                                _buildHeaderCell(width: 120, height: 24, text: _getExcelLetter(days.length + 4), isLetter: true),
                              ],
                            ),

                            // Headers Row 2: Weeks Row span
                            _buildWeeksHeaderRow(days),

                            // Headers Row 3: Day Names (Su, Mo, Tu...)
                            Row(
                              children: [
                                ...days.map((day) {
                                  final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                                  return _buildHeaderCell(
                                    width: 36,
                                    height: 28,
                                    text: DateFormat('E').format(day).substring(0, 2),
                                    backgroundColor: isWeekend ? const Color(0xfff1f5f9) : const Color(0xfff8fafc),
                                    textColor: isWeekend ? const Color(0xff94a3b8) : const Color(0xff475569),
                                  );
                                }).toList(),
                                _buildHeaderCell(width: 44, height: 28, text: 'Goal', fontWeight: FontWeight.bold, backgroundColor: const Color(0xfff8fafc)),
                                _buildHeaderCell(width: 44, height: 28, text: 'Act', fontWeight: FontWeight.bold, backgroundColor: const Color(0xfff8fafc)),
                                _buildHeaderCell(width: 120, height: 28, text: 'Progress', fontWeight: FontWeight.bold, backgroundColor: const Color(0xfff8fafc)),
                              ],
                            ),

                            // Headers Row 4: Day Numbers (1, 2, 3...)
                            Row(
                              children: [
                                ...days.map((day) {
                                  final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                                  return _buildHeaderCell(
                                    width: 36,
                                    height: 28,
                                    text: day.day.toString(),
                                    backgroundColor: isWeekend ? const Color(0xfff1f5f9) : const Color(0xfff8fafc),
                                    textColor: isWeekend ? const Color(0xff94a3b8) : const Color(0xff475569),
                                    isMono: true,
                                  );
                                }).toList(),
                                _buildHeaderCell(width: 44, height: 28, text: '(D)', isLetter: true, backgroundColor: const Color(0xfff8fafc)),
                                _buildHeaderCell(width: 44, height: 28, text: '(D)', isLetter: true, backgroundColor: const Color(0xfff8fafc)),
                                _buildHeaderCell(width: 120, height: 28, text: '(%)', isLetter: true, backgroundColor: const Color(0xfff8fafc)),
                              ],
                            ),

                            // Data Rows Container (Checkboxes and analysis)
                            Expanded(
                              child: ListView.builder(
                                controller: _rightVerticalController,
                                itemCount: widget.habits.length + 3,
                                itemExtent: 32,
                                itemBuilder: (context, index) {
                                  if (index < widget.habits.length) {
                                    final habit = widget.habits[index];
                                    
                                    // Count completions
                                    final actualCount = habit.done.keys.where((k) {
                                      final d = DateTime.tryParse(k);
                                      return d != null && d.year == year && d.month == month && habit.done[k] == true;
                                    }).length;
                                    final double progressPct = habit.goalDays > 0 ? (actualCount / habit.goalDays).clamp(0.0, 1.0) : 0.0;

                                    return Row(
                                      children: [
                                        // Days cells checkboxes
                                        ...days.map((day) {
                                          final dateStr = Habit.formatDateKey(day);
                                          final isChecked = habit.done[dateStr] == true;
                                          final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

                                          return _buildCheckboxCell(
                                            width: 36,
                                            isChecked: isChecked,
                                            isWeekend: isWeekend,
                                            onTap: () {
                                              widget.onToggleDone(habit.id, dateStr);
                                            },
                                          );
                                        }).toList(),

                                        // Goal
                                        _buildAnalysisCell(width: 44, text: habit.goalDays.toString()),
                                        
                                        // Actual completions
                                        _buildAnalysisCell(
                                          width: 44,
                                          text: actualCount.toString(),
                                          textColor: const Color(0xff13854e),
                                        ),

                                        // Progress visual bar
                                        _buildProgressBarCell(
                                          width: 120,
                                          percentage: progressPct,
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Stat Rows numbers
                                    final statIndex = index - widget.habits.length;
                                    return _buildStatRowValues(days, statIndex);
                                  }
                                },
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Synced header cell for frozen panel
  Widget _buildLeftHeaderCell({
    required double height,
    required String text,
    required String textB,
    bool isLetter = false,
    FontWeight? fontWeightB,
    Color? color,
  }) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xfff1f5f9),
        border: Border(
          right: BorderSide(color: Color(0xffcbd5e1)),
          bottom: BorderSide(color: Color(0xffcbd5e1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xffe2e8f0),
              border: Border(right: BorderSide(color: Color(0xffcbd5e1))),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.black,
                color: isLetter ? const Color(0xff94a3b8) : const Color(0xff64748b),
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: color,
              alignment: Alignment.center,
              child: Text(
                textB,
                style: TextStyle(
                  fontSize: isLetter ? 9 : 10,
                  fontWeight: isLetter ? FontWeight.black : (fontWeightB ?? FontWeight.normal),
                  color: isLetter ? const Color(0xff94a3b8) : const Color(0xff64748b),
                  fontFamily: isLetter ? 'monospace' : null,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Frozen data cell for index and habit name
  Widget _buildLeftRowCell({
    required int rowIndex,
    required String habitEmoji,
    required String habitName,
  }) {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xffcbd5e1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xfff8fafc),
              border: Border(
                right: BorderSide(color: Color(0xffcbd5e1)),
              ),
            ),
            child: Text(
              rowIndex.toString(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.black,
                color: Color(0xff94a3b8),
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              color: const Color(0xffe2f0d9), // Mint green
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(habitEmoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      habitName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1e293b),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Left stat cells (Σ, ✓, ✗ labels)
  Widget _buildLeftStatCell({
    required String sigma,
    required String label,
  }) {
    return Container(
      height: 32,
      color: const Color(0xfff1f5f9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xffcbd5e1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xffe2e8f0),
              border: Border(
                right: BorderSide(color: Color(0xffcbd5e1)),
              ),
            ),
            child: Text(
              sigma,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.black,
                color: Color(0xff64748b),
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff475569),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Generic header cell
  Widget _buildHeaderCell({
    required double width,
    required double height,
    required String text,
    bool isLetter = false,
    bool isMono = false,
    Color backgroundColor = const Color(0xfff1f5f9),
    Color textColor = const Color(0xff94a3b8),
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          right: BorderSide(color: Color(0xffcbd5e1)),
          bottom: BorderSide(color: Color(0xffcbd5e1)),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isLetter ? 9 : 10,
          fontWeight: isLetter ? FontWeight.black : fontWeight,
          color: textColor,
          fontFamily: (isLetter || isMono) ? 'monospace' : null,
        ),
      ),
    );
  }

  // Weeks spanning Row
  Widget _buildWeeksHeaderRow(List<DateTime> days) {
    // Group days by calendar week indices
    final List<Map<String, dynamic>> spans = [];
    int currentWeekIndex = -1;
    int currentSpan = 0;

    for (var day in days) {
      // Simple ISO week calculation
      final int weekIndex = ((day.day + DateTime(day.year, day.month, 1).weekday) / 7).ceil();
      if (weekIndex == currentWeekIndex) {
        currentSpan++;
      } else {
        if (currentWeekIndex != -1) {
          spans.add({'week': currentWeekIndex, 'span': currentSpan});
        }
        currentWeekIndex = weekIndex;
        currentSpan = 1;
      }
    }
    spans.add({'week': currentWeekIndex, 'span': currentSpan});

    return Row(
      children: [
        ...spans.map((s) {
          final int spanCount = s['span'] as int;
          final int weekNum = s['week'] as int;
          return Container(
            width: spanCount * 36.0,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xfff8fafc),
              border: Border(
                right: BorderSide(color: Color(0xffcbd5e1)),
                bottom: BorderSide(color: Color(0xffcbd5e1)),
              ),
            ),
            child: Text(
              'WEEK $weekNum',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xff94a3b8),
                letterSpacing: 0.8,
                fontFamily: 'monospace',
              ),
            ),
          );
        }).toList(),
        
        // Analysis Span
        Container(
          width: 208, // 44 + 44 + 120
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xffe2e8f0),
            border: Border(
              bottom: BorderSide(color: Color(0xffcbd5e1)),
            ),
          ),
          child: const Text(
            'ANALYSIS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.black,
              color: Color(0xff475569),
              letterSpacing: 1.2,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  // Checkbox Grid Cell
  Widget _buildCheckboxCell({
    required double width,
    required bool isChecked,
    required bool isWeekend,
    required VoidCallback onTap,
  }) {
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: isWeekend ? const Color(0xfff8fafc) : Colors.white,
        border: const Border(
          right: BorderSide(color: Color(0xffcbd5e1)),
          bottom: BorderSide(color: Color(0xffcbd5e1)),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xff1e293b) : Colors.white,
              border: Border.all(
                color: isChecked ? const Color(0xff1e293b) : const Color(0xffcbd5e1),
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }

  // Generic Analysis Data Cell
  Widget _buildAnalysisCell({
    required double width,
    required String text,
    Color textColor = const Color(0xff475569),
  }) {
    return Container(
      width: width,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        border: Border(
          right: BorderSide(color: Color(0xffcbd5e1)),
          bottom: BorderSide(color: Color(0xffcbd5e1)),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  // Progress Bar Cell
  Widget _buildProgressBarCell({
    required double width,
    required double percentage,
  }) {
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        color: Color(0xfff8fafc),
        border: Border(
          bottom: BorderSide(color: Color(0xffcbd5e1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: const Color(0xffe2e8f0),
                color: const Color(0xff22c55e),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            child: Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              textAlign: javaStringFormatAlignRight(),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Color(0xff475569),
                fontFamily: 'monospace',
              ),
            ),
          )
        ],
      ),
    );
  }

  TextAlign javaStringFormatAlignRight() => TextAlign.right;

  // Calculates and returns the daily statistics rows in the scrollable body
  Widget _buildStatRowValues(List<DateTime> days, int statIndex) {
    return Row(
      children: [
        ...days.map((day) {
          final dateStr = Habit.formatDateKey(day);
          final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
          
          int completedCount = 0;
          for (var h in widget.habits) {
            if (h.done[dateStr] == true) completedCount++;
          }

          String text = '';
          Color textColor = const Color(0xff334155);

          if (statIndex == 0) {
            // Progress in %
            final pct = widget.habits.isNotEmpty ? (completedCount / widget.habits.length * 100).round() : 0;
            text = '$pct%';
          } else if (statIndex == 1) {
            // Completed
            text = completedCount.toString();
            textColor = const Color(0xff13854e);
          } else {
            // Remaining
            text = (widget.habits.length - completedCount).toString();
            textColor = const Color(0xffef4444);
          }

          return Container(
            width: 36,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWeekend ? const Color(0xfff1f5f9) : const Color(0xfff8fafc),
              border: const Border(
                right: BorderSide(color: Color(0xffcbd5e1)),
                bottom: BorderSide(color: Color(0xffcbd5e1)),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: statIndex == 0 ? 8 : 10,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'monospace',
              ),
            ),
          );
        }).toList(),

        // Safe padding for Analysis columns on bottom row
        Container(
          width: 208,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xfff1f5f9),
            border: Border(
              bottom: BorderSide(color: Color(0xffcbd5e1)),
            ),
          ),
        ),
      ],
    );
  }
}
