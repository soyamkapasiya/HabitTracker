'use client';

import React, { useState, useMemo, useEffect } from 'react';
import * as Icons from 'lucide-react';
import {
  useUltimateHabitTracker,
  Habit,
  getLocalDateString,
  calculateStreak,
  CATS
} from '@/hooks/useUltimateHabitTracker';

// Helper to get Excel column letter (0 -> A, 1 -> B, 2 -> C, etc.)
function getExcelColumnLetter(index: number): string {
  let label = '';
  let temp = index;
  while (temp >= 0) {
    label = String.fromCharCode((temp % 26) + 65) + label;
    temp = Math.floor(temp / 26) - 1;
  }
  return label;
}

// Custom SVGs for SVG Donut Chart
function DonutChart({ percentage, size = 72, strokeWidth = 7 }: { percentage: number; size?: number; strokeWidth?: number }) {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const strokeDashoffset = circumference - (percentage / 100) * circumference;

  return (
    <div className="relative flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="transform -rotate-90">
        {/* Unfilled track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          className="stroke-[#e2f0d9] fill-transparent"
          strokeWidth={strokeWidth}
        />
        {/* Progress path */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          className="stroke-[#13854e] fill-transparent transition-all duration-500 ease-out"
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          strokeLinecap="round"
        />
      </svg>
      <span className="absolute text-[11px] font-black text-slate-800 font-mono">{percentage}%</span>
    </div>
  );
}

const POPULAR_EMOJIS = ['⏰', '💪', '🔞', '📖', '💰', '🎯', '🚫', '🌿', '📒', '🚿', '💧', '🏃', '🧘', '💻', '☀️', '🥦'];

export function UltimateHabitTracker() {
  const { habits, loading, toggleDone, addHabit, updateHabit, deleteHabit } = useUltimateHabitTracker();
  
  const [mounted, setMounted] = useState(false);
  const [activeTab, setActiveTab] = useState<'grid' | 'dashboard' | 'manage'>('grid');
  
  // Date States
  const [currentMonthDate, setCurrentMonthDate] = useState<Date>(new Date());
  
  // Daily dashboard week start state (starts on Monday of the current week)
  const [currentWeekStart, setCurrentWeekStart] = useState<Date>(() => {
    const d = new Date();
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1); // adjust when day is sunday
    return new Date(d.setDate(diff));
  });

  // Edit / Add Modal States
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingHabit, setEditingHabit] = useState<Habit | null>(null);
  const [habitName, setHabitName] = useState('');
  const [habitEmoji, setHabitEmoji] = useState('⭐');
  const [habitGoal, setHabitGoal] = useState(30);
  const [habitCat, setHabitCat] = useState(0);
  const [habitDesc, setHabitDesc] = useState('');

  // Toast Notification State
  const [toast, setToast] = useState<{ message: string; sub?: string } | null>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Toast Auto-dismiss
  useEffect(() => {
    if (toast) {
      const timer = setTimeout(() => setToast(null), 3000);
      return () => clearTimeout(timer);
    }
  }, [toast]);

  // Handle Quick toggle completions
  const handleToggleDone = (habitId: string, dateKey: string) => {
    const habit = habits.find(h => h.id === habitId);
    if (!habit) return;
    
    const isNowDone = !habit.done[dateKey];
    toggleDone(habitId, dateKey);

    if (isNowDone) {
      const tempDone = { ...habit.done, [dateKey]: true };
      const { current } = calculateStreak(tempDone);
      
      setToast({
        message: `Completed: ${habit.name}`,
        sub: current >= 3 ? `🔥 ${current}-day streak! Keep going!` : `✨ Standard habit logged!`
      });
    }
  };

  // CSV Export utility
  const handleCSVExport = () => {
    if (habits.length === 0) return;
    
    // Generate dates for current month
    const year = currentMonthDate.getFullYear();
    const month = currentMonthDate.getMonth();
    const totalDays = new Date(year, month + 1, 0).getDate();
    
    const datesList: string[] = [];
    for (let day = 1; day <= totalDays; day++) {
      const d = new Date(year, month, day);
      datesList.push(getLocalDateString(d));
    }

    // Build headers
    const headers = ['Habit Name', 'Emoji', 'Category', 'Goal Target (Days)', 'Actual (Days)', 'Progress %', ...datesList];
    
    // Build rows
    const rows = habits.map(h => {
      const actualCount = Object.keys(h.done).filter(k => {
        const d = new Date(k);
        return d.getFullYear() === year && d.getMonth() === month && h.done[k];
      }).length;
      
      const pct = Math.round((actualCount / (h.goalDays || 30)) * 100);
      const completions = datesList.map(dateKey => h.done[dateKey] ? '1' : '0');
      
      return [
        h.name,
        h.emoji || '',
        CATS[h.cat]?.name || '',
        h.goalDays || 30,
        actualCount,
        `${pct}%`,
        ...completions
      ];
    });

    // Construct CSV String
    const csvContent = [headers.map(h => `"${h}"`).join(','), ...rows.map(r => r.map(v => `"${v}"`).join(','))].join('\n');
    
    // Download logic
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `habit_tracker_${currentMonthDate.toLocaleString('default', { month: 'long' })}_${year}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Open Modal
  const openModal = (habit: Habit | null = null) => {
    if (habit) {
      setEditingHabit(habit);
      setHabitName(habit.name);
      setHabitEmoji(habit.emoji || '⭐');
      setHabitGoal(habit.goalDays || 30);
      setHabitCat(habit.cat);
      setHabitDesc(habit.description || '');
    } else {
      setEditingHabit(null);
      setHabitName('');
      setHabitEmoji('⏰');
      setHabitGoal(30);
      setHabitCat(0);
      setHabitDesc('');
    }
    setIsModalOpen(true);
  };

  // Save Modal Form
  const handleSaveForm = (e: React.FormEvent) => {
    e.preventDefault();
    if (!habitName.trim()) return;

    if (editingHabit) {
      updateHabit(editingHabit.id, habitName, habitCat, 'daily', habitDesc, habitEmoji, habitGoal);
      setToast({ message: 'Habit updated successfully' });
    } else {
      addHabit(habitName, habitCat, 'daily', habitDesc, habitEmoji, habitGoal);
      setToast({ message: 'New habit created!' });
    }
    setIsModalOpen(false);
  };

  // Calculate dynamic days list for monthly grid view
  const daysInMonth = useMemo(() => {
    const year = currentMonthDate.getFullYear();
    const month = currentMonthDate.getMonth();
    const totalDays = new Date(year, month + 1, 0).getDate();
    
    const days = [];
    for (let day = 1; day <= totalDays; day++) {
      const dateObj = new Date(year, month, day);
      const dateKey = getLocalDateString(dateObj);
      const dayOfWeekNum = dateObj.getDay(); // 0: Sun, 1: Mon, etc.
      const dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
      
      // Calculate week index in month for headers grouping
      // Standard Excel spreadsheet lists Week numbers
      const weekIndex = Math.ceil((day + new Date(year, month, 1).getDay()) / 7);

      days.push({
        dayNum: day,
        dateKey,
        dayName: dayNames[dayOfWeekNum],
        weekIndex,
        isWeekend: dayOfWeekNum === 0 || dayOfWeekNum === 6
      });
    }
    return days;
  }, [currentMonthDate]);

  // Group columns by week for week header row span
  const weekSpans = useMemo(() => {
    const groups: { weekIndex: number; span: number }[] = [];
    daysInMonth.forEach(d => {
      const last = groups[groups.length - 1];
      if (last && last.weekIndex === d.weekIndex) {
        last.span += 1;
      } else {
        groups.push({ weekIndex: d.weekIndex, span: 1 });
      }
    });
    return groups;
  }, [daysInMonth]);

  // Grid level overall statistics
  const gridStats = useMemo(() => {
    if (habits.length === 0) return { totalGoal: 0, totalActual: 0, overallPct: 0 };
    
    let totalGoal = 0;
    let totalActual = 0;
    
    const year = currentMonthDate.getFullYear();
    const month = currentMonthDate.getMonth();

    habits.forEach(h => {
      totalGoal += h.goalDays || 30;
      
      // Count completions in current selected month
      const actualMonthCompletions = Object.keys(h.done).filter(k => {
        const d = new Date(k);
        return d.getFullYear() === year && d.getMonth() === month && h.done[k];
      }).length;
      
      totalActual += actualMonthCompletions;
    });

    const overallPct = totalGoal > 0 ? Math.round((totalActual / totalGoal) * 10000) / 100 : 0;

    return {
      totalGoal,
      totalActual,
      overallPct
    };
  }, [habits, currentMonthDate]);

  // Daily checklists for current selected week (Dashboard view)
  const dashboardWeekDays = useMemo(() => {
    const list = [];
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    for (let i = 0; i < 7; i++) {
      const d = new Date(currentWeekStart);
      d.setDate(currentWeekStart.getDate() + i);
      const dateKey = getLocalDateString(d);
      
      // Format date in DD.MM.YYYY
      const formattedDate = `${String(d.getDate()).padStart(2, '0')}.${String(d.getMonth() + 1).padStart(2, '0')}.${d.getFullYear()}`;

      // Calculate progress
      let completed = 0;
      habits.forEach(h => {
        if (h.done[dateKey]) completed++;
      });
      const total = habits.length;
      const pct = total > 0 ? Math.round((completed / total) * 100) : 0;

      list.push({
        dayName: dayNames[d.getDay()],
        dateStr: formattedDate,
        dateKey,
        pct,
        completedCount: completed,
        totalCount: total
      });
    }
    return list;
  }, [habits, currentWeekStart]);

  // Dashboard overall weekly completion stats (Image 3 header)
  const weeklyOverallStats = useMemo(() => {
    let completedTotal = 0;
    const totalPossible = habits.length * 7;
    
    dashboardWeekDays.forEach(day => {
      completedTotal += day.completedCount;
    });

    const pct = totalPossible > 0 ? Math.round((completedTotal / totalPossible) * 100) : 0;

    return {
      completed: completedTotal,
      possible: totalPossible,
      pct
    };
  }, [habits, dashboardWeekDays]);

  if (!mounted) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-slate-50 text-slate-500 font-sans">
        <div className="flex flex-col items-center gap-2">
          <Icons.Loader2 className="w-8 h-8 text-[#13854e] animate-spin" />
          <p className="text-xs font-bold font-mono">LOADING WORKSPACE...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full h-full flex flex-col bg-[#f6f8fa] text-slate-800 font-sans select-none overflow-hidden">
      
      {/* Toast Notification */}
      {toast && (
        <div className="fixed top-6 right-6 z-[250] flex flex-col bg-white border-l-4 border-[#13854e] shadow-lg rounded-md px-4 py-3 min-w-[280px] animate-in slide-in-from-top-5 duration-300">
          <div className="text-xs font-black text-slate-800 leading-tight flex items-center gap-1.5">
            <Icons.CheckCircle2 className="w-4 h-4 text-[#13854e]" />
            <span>{toast.message}</span>
          </div>
          {toast.sub && <div className="text-[10px] text-slate-500 font-mono mt-1 pl-5">{toast.sub}</div>}
        </div>
      )}

      {/* Main Top Header Controls */}
      <header className="h-14 bg-white border-b border-slate-200 flex items-center justify-between px-6 z-30 shrink-0">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded bg-[#13854e] flex items-center justify-center text-white shadow-sm font-bold text-sm">
              田
            </div>
            <div>
              <h1 className="text-sm font-bold text-slate-900 tracking-tight leading-none">Automated Dashboard</h1>
              <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider mt-0.5">Automated Spreadsheet Tracker</p>
            </div>
          </div>

          <div className="h-6 w-px bg-slate-200" />

          {/* Navigation Tabs */}
          <nav className="flex items-center bg-slate-100 p-1 rounded-lg gap-1">
            <button
              onClick={() => setActiveTab('grid')}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-md text-[11px] font-bold tracking-tight transition-all ${
                activeTab === 'grid'
                  ? 'bg-white shadow-sm text-slate-900'
                  : 'text-slate-500 hover:text-slate-800 hover:bg-slate-50'
              }`}
            >
              <Icons.Table className="w-3.5 h-3.5" />
              <span>Spreadsheet Grid</span>
            </button>
            <button
              onClick={() => setActiveTab('dashboard')}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-md text-[11px] font-bold tracking-tight transition-all ${
                activeTab === 'dashboard'
                  ? 'bg-white shadow-sm text-slate-900'
                  : 'text-slate-500 hover:text-slate-800 hover:bg-slate-50'
              }`}
            >
              <Icons.LayoutDashboard className="w-3.5 h-3.5" />
              <span>Daily Donut Dashboard</span>
            </button>
            <button
              onClick={() => setActiveTab('manage')}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-md text-[11px] font-bold tracking-tight transition-all ${
                activeTab === 'manage'
                  ? 'bg-white shadow-sm text-slate-900'
                  : 'text-slate-500 hover:text-slate-800 hover:bg-slate-50'
              }`}
            >
              <Icons.Settings className="w-3.5 h-3.5" />
              <span>Configure Habits</span>
            </button>
          </nav>
        </div>

        <div className="flex items-center gap-2">
          {/* Download CSV button matching image download action */}
          <button
            onClick={handleCSVExport}
            className="flex items-center gap-1.5 px-3.5 py-1.5 bg-white border border-slate-300 hover:bg-slate-50 rounded-lg text-[11px] font-bold text-slate-700 shadow-sm transition-all active:scale-95 cursor-pointer"
          >
            <Icons.Download className="w-3.5 h-3.5" />
            <span>Download Template</span>
          </button>
          
          <button
            onClick={() => openModal()}
            className="flex items-center gap-1 px-3.5 py-1.5 bg-[#13854e] hover:bg-[#0f6c3e] text-white rounded-lg text-[11px] font-bold shadow-sm transition-all active:scale-95 cursor-pointer"
          >
            <Icons.Plus className="w-3.5 h-3.5" />
            <span>Add Habit</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <div className="flex-1 overflow-hidden relative flex flex-col">
        
        {/* VIEW 1: SPREADSHEET GRID */}
        {activeTab === 'grid' && (
          <div className="flex-1 flex flex-col overflow-hidden p-6 gap-6">
            
            {/* Dynamic Formula bar / Top grid controls */}
            <div className="flex items-center justify-between shrink-0 bg-white border border-slate-200 rounded-xl p-4 shadow-sm">
              <div className="flex items-center gap-4">
                <div className="flex flex-col gap-0.5">
                  <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Active month</span>
                  <div className="flex items-center gap-1.5">
                    <button
                      onClick={() => {
                        const newDate = new Date(currentMonthDate);
                        newDate.setMonth(newDate.getMonth() - 1);
                        setCurrentMonthDate(newDate);
                      }}
                      className="p-1 rounded hover:bg-slate-100 text-slate-500 hover:text-slate-800 transition-colors"
                    >
                      <Icons.ChevronLeft className="w-4 h-4" />
                    </button>
                    <span className="text-xs font-bold text-slate-800 font-mono w-28 text-center uppercase tracking-wide">
                      {currentMonthDate.toLocaleString('default', { month: 'long', year: 'numeric' })}
                    </span>
                    <button
                      onClick={() => {
                        const newDate = new Date(currentMonthDate);
                        newDate.setMonth(newDate.getMonth() + 1);
                        setCurrentMonthDate(newDate);
                      }}
                      className="p-1 rounded hover:bg-slate-100 text-slate-500 hover:text-slate-800 transition-colors"
                    >
                      <Icons.ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                <div className="h-8 w-px bg-slate-200" />
                
                {/* Total Stats formula box */}
                <div className="flex items-center gap-4 bg-[#f8fafc] border border-slate-200/60 rounded-lg px-4 py-1.5">
                  <div className="flex flex-col">
                    <span className="text-[9px] text-slate-400 font-black uppercase tracking-wider font-mono">Progress in %</span>
                    <span className="text-base font-black text-[#13854e] font-mono leading-none mt-0.5">{gridStats.overallPct}%</span>
                  </div>
                  <div className="flex flex-col w-28">
                    <span className="text-[8px] text-slate-400 font-bold uppercase tracking-wider mb-1">Grid Completion</span>
                    <div className="w-full bg-slate-200 h-2.5 rounded-full overflow-hidden border border-slate-300/40">
                      <div className="bg-[#22c55e] h-full transition-all duration-700" style={{ width: `${Math.min(100, gridStats.overallPct)}%` }} />
                    </div>
                  </div>
                </div>
              </div>

              <div className="text-[10px] text-slate-400 font-mono font-semibold">
                Formula: =SUM(Actual) / SUM(Goal)
              </div>
            </div>

            {/* Grid Container */}
            <div className="flex-1 bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden flex flex-col">
              
              {/* Spreadsheet Table Scroll Container */}
              <div className="flex-1 overflow-auto custom-scrollbar">
                
                <table className="w-full border-separate border-spacing-0 text-left relative table-fixed">
                  <thead>
                    
                    {/* ROW 1: Excel alphabet letter headers (Freeze top) */}
                    <tr className="bg-slate-50 select-none">
                      <th className="w-[40px] bg-slate-100 border-r border-b border-slate-200 sticky top-0 left-0 z-40 text-center text-[9px] font-black text-slate-400 font-mono h-6">
                        {getExcelColumnLetter(0)}
                      </th>
                      <th className="w-[200px] bg-slate-100 border-r border-b border-slate-200 sticky top-0 left-[40px] z-40 text-center text-[9px] font-black text-slate-400 font-mono">
                        {getExcelColumnLetter(1)}
                      </th>
                      {daysInMonth.map((day, idx) => (
                        <th key={`letter-${day.dateKey}`} className="w-[38px] bg-slate-100 border-r border-b border-slate-200 sticky top-0 z-30 text-center text-[9px] font-black text-slate-400 font-mono">
                          {getExcelColumnLetter(idx + 2)}
                        </th>
                      ))}
                      {/* Analysis Column letters */}
                      <th className="w-[60px] bg-slate-100 border-r border-b border-slate-200 sticky top-0 z-30 text-center text-[9px] font-black text-slate-400 font-mono">
                        {getExcelColumnLetter(daysInMonth.length + 2)}
                      </th>
                      <th className="w-[60px] bg-slate-100 border-r border-b border-slate-200 sticky top-0 z-30 text-center text-[9px] font-black text-slate-400 font-mono">
                        {getExcelColumnLetter(daysInMonth.length + 3)}
                      </th>
                      <th className="w-[140px] bg-slate-100 border-b border-slate-200 sticky top-0 z-30 text-center text-[9px] font-black text-slate-400 font-mono">
                        {getExcelColumnLetter(daysInMonth.length + 4)}
                      </th>
                    </tr>

                    {/* ROW 2: Week Numbers (Freeze top) */}
                    <tr className="bg-slate-50">
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[24px] left-0 z-40 h-6 text-center text-[9px] text-slate-400 font-mono font-bold select-none">
                        {/* empty */}
                      </th>
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[24px] left-[40px] z-40 text-center text-[10px] text-slate-400 font-mono font-bold select-none">
                        {/* empty */}
                      </th>
                      {weekSpans.map((week, idx) => (
                        <th
                          key={`week-${idx}`}
                          colSpan={week.span}
                          className="bg-slate-50 border-r border-b border-slate-200 sticky top-[24px] z-30 text-center text-[10px] font-bold text-slate-400 font-mono uppercase tracking-wider border-t border-t-slate-200/50"
                        >
                          Week {week.weekIndex}
                        </th>
                      ))}
                      {/* Analysis Header */}
                      <th colSpan={3} className="bg-slate-100 border-b border-slate-200 sticky top-[24px] z-30 text-center text-[10px] font-black text-slate-600 font-mono uppercase tracking-widest border-t border-t-slate-200/50">
                        Analysis
                      </th>
                    </tr>

                    {/* ROW 3: Days names (Su, Mo...) (Freeze top) */}
                    <tr className="bg-slate-50">
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[48px] left-0 z-40 h-7 text-center text-[9px] text-slate-400 font-mono font-bold select-none">
                        {/* empty */}
                      </th>
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[48px] left-[40px] z-40 text-center text-[10px] text-slate-500 font-bold select-none">
                        {/* empty */}
                      </th>
                      {daysInMonth.map(day => (
                        <th
                          key={`name-${day.dateKey}`}
                          className={`border-r border-b border-slate-200 sticky top-[48px] z-30 text-center text-[10px] font-bold select-none py-1 ${
                            day.isWeekend ? 'bg-slate-100/70 text-slate-400' : 'bg-slate-50 text-slate-600'
                          }`}
                        >
                          {day.dayName}
                        </th>
                      ))}
                      {/* Analysis Column Subtitles */}
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[48px] z-30 text-center text-[10px] font-bold text-slate-500 py-1">
                        Goal
                      </th>
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[48px] z-30 text-center text-[10px] font-bold text-slate-500 py-1">
                        Actual
                      </th>
                      <th className="bg-slate-50 border-b border-slate-200 sticky top-[48px] z-30 text-center text-[10px] font-bold text-slate-500 py-1">
                        Progress
                      </th>
                    </tr>

                    {/* ROW 4: Date Numbers (1, 2, 3...) (Freeze top) */}
                    <tr className="bg-slate-50">
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[76px] left-0 z-40 h-7 text-center text-[9px] text-slate-400 font-mono font-bold select-none">
                        {/* empty */}
                      </th>
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[76px] left-[40px] z-40 text-center text-[10px] text-slate-500 font-bold select-none">
                        My Habits
                      </th>
                      {daysInMonth.map(day => (
                        <th
                          key={`num-${day.dateKey}`}
                          className={`border-r border-b border-slate-200 sticky top-[76px] z-30 text-center text-xs font-mono font-bold select-none ${
                            day.isWeekend ? 'bg-slate-100/70 text-slate-400' : 'bg-slate-50 text-slate-600'
                          }`}
                        >
                          {day.dayNum}
                        </th>
                      ))}
                      {/* Analysis column placeholder headers */}
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[76px] z-30 font-bold text-center select-none text-[9px] text-slate-400">
                        (Days)
                      </th>
                      <th className="bg-slate-50 border-r border-b border-slate-200 sticky top-[76px] z-30 font-bold text-center select-none text-[9px] text-slate-400">
                        (Days)
                      </th>
                      <th className="bg-slate-50 border-b border-slate-200 sticky top-[76px] z-30 font-bold text-center select-none text-[9px] text-slate-400">
                        (%)
                      </th>
                    </tr>

                  </thead>
                  <tbody>
                    {habits.map((habit, rowIndex) => {
                      // Calculate actual completions in current month
                      const actualMonthCount = Object.keys(habit.done).filter(k => {
                        const d = new Date(k);
                        return d.getFullYear() === currentMonthDate.getFullYear() && 
                               d.getMonth() === currentMonthDate.getMonth() && 
                               habit.done[k];
                      }).length;

                      const goalVal = habit.goalDays || 30;
                      const progressPercentage = Math.min(100, Math.round((actualMonthCount / goalVal) * 100));

                      return (
                        <tr key={habit.id} className="hover:bg-slate-50/50 group h-8">
                          
                          {/* Col 0: Spreadsheet Row Numbers (Freeze Left) */}
                          <td className="bg-slate-50 border-r border-b border-slate-200 sticky left-0 z-20 text-center text-[9px] font-mono font-black text-slate-400 select-none">
                            {rowIndex + 1}
                          </td>

                          {/* Col 1: Sticky Habit Name and Emoji with Minty background (Freeze Left) */}
                          <td className="bg-[#e2f0d9] border-r border-b border-[#cbd5e1] sticky left-[40px] z-20 px-3 truncate text-xs font-bold text-slate-800 flex items-center justify-between h-8">
                            <span className="truncate flex items-center gap-1.5">
                              <span className="text-sm select-none">{habit.emoji || '⭐'}</span>
                              <span className="truncate leading-none">{habit.name}</span>
                            </span>
                            <button
                              onClick={() => openModal(habit)}
                              className="opacity-0 group-hover:opacity-100 p-0.5 rounded hover:bg-[#cbd5e1] text-slate-500 hover:text-slate-800 transition-all ml-1 cursor-pointer shrink-0"
                            >
                              <Icons.Edit className="w-3 h-3" />
                            </button>
                          </td>

                          {/* Days checkboxes cells */}
                          {daysInMonth.map(day => {
                            const isDone = !!habit.done[day.dateKey];
                            return (
                              <td
                                key={`${habit.id}-${day.dateKey}`}
                                className={`border-r border-b border-slate-200 text-center p-0 h-8 select-none transition-colors ${
                                  day.isWeekend ? 'bg-slate-50/50' : 'bg-white'
                                }`}
                              >
                                <div
                                  onClick={() => handleToggleDone(habit.id, day.dateKey)}
                                  className="w-full h-full flex items-center justify-center cursor-pointer hover:bg-slate-100/50 active:bg-slate-200/50 transition-all"
                                >
                                  {/* Authentic excel checkbox style checkmark block */}
                                  <div className={`w-3.5 h-3.5 rounded border flex items-center justify-center transition-all ${
                                    isDone
                                      ? 'bg-slate-800 border-slate-800 text-white'
                                      : 'border-slate-300 bg-white hover:border-slate-500'
                                  }`}>
                                    {isDone && <Icons.Check className="w-2.5 h-2.5 stroke-[3]" />}
                                  </div>
                                </div>
                              </td>
                            );
                          })}

                          {/* Right Side: Analysis Data */}
                          {/* Goal Target Days */}
                          <td className="bg-slate-50 border-r border-b border-slate-200 px-2 font-mono font-bold text-center text-xs text-slate-600">
                            {goalVal}
                          </td>
                          {/* Actual Completed Days */}
                          <td className="bg-slate-50 border-r border-b border-slate-200 px-2 font-mono font-bold text-center text-xs text-[#13854e]">
                            {actualMonthCount}
                          </td>
                          {/* Progress bar and text */}
                          <td className="bg-slate-50 border-b border-slate-200 px-3 text-center text-xs py-1 h-8">
                            <div className="flex items-center gap-2 w-full h-full">
                              <div className="flex-1 bg-slate-200 h-2 rounded-full overflow-hidden border border-slate-300/40">
                                <div className="bg-[#22c55e] h-full transition-all duration-500" style={{ width: `${progressPercentage}%` }} />
                              </div>
                              <span className="font-mono font-bold text-[10px] text-slate-600 shrink-0 w-8 text-right">
                                {progressPercentage}%
                              </span>
                            </div>
                          </td>

                        </tr>
                      );
                    })}

                    {/* STATISTICS ROW 1: Progress % (Dynamic formula cells) */}
                    <tr className="bg-slate-50 h-8 font-bold">
                      <td className="bg-slate-100 border-r border-b border-slate-200 sticky left-0 z-20 text-center text-[9px] font-mono font-black text-slate-400 select-none">
                        Σ
                      </td>
                      <td className="bg-slate-100 border-r border-b border-slate-200 sticky left-[40px] z-20 px-3 text-[10px] text-slate-500 font-mono tracking-tight font-black">
                        Progress in %
                      </td>
                      {daysInMonth.map(day => {
                        let completedCount = 0;
                        habits.forEach(h => {
                          if (h.done[day.dateKey]) completedCount++;
                        });
                        const pct = habits.length > 0 ? Math.round((completedCount / habits.length) * 100) : 0;
                        return (
                          <td key={`prog-pct-${day.dateKey}`} className={`border-r border-b border-slate-200 text-center font-mono text-[10px] text-slate-700 ${
                            day.isWeekend ? 'bg-slate-100/70' : 'bg-slate-50'
                          }`}>
                            {pct}%
                          </td>
                        );
                      })}
                      {/* Analysis Column Placeholders */}
                      <td colSpan={3} className="bg-slate-100 border-b border-slate-200" />
                    </tr>

                    {/* STATISTICS ROW 2: Checked Counts */}
                    <tr className="bg-slate-50 h-8 font-bold">
                      <td className="bg-slate-100 border-r border-b border-slate-200 sticky left-0 z-20 text-center text-[9px] font-mono font-black text-slate-400 select-none">
                        ✓
                      </td>
                      <td className="bg-slate-100 border-r border-b border-slate-200 sticky left-[40px] z-20 px-3 text-[10px] text-slate-500 font-mono tracking-tight font-black">
                        Completed (Checked)
                      </td>
                      {daysInMonth.map(day => {
                        let completedCount = 0;
                        habits.forEach(h => {
                          if (h.done[day.dateKey]) completedCount++;
                        });
                        return (
                          <td key={`prog-chk-${day.dateKey}`} className={`border-r border-b border-slate-200 text-center font-mono text-xs text-[#13854e] ${
                            day.isWeekend ? 'bg-slate-100/70' : 'bg-slate-50'
                          }`}>
                            {completedCount}
                          </td>
                        );
                      })}
                      {/* Analysis Column Placeholders */}
                      <td colSpan={3} className="bg-slate-100 border-b border-slate-200" />
                    </tr>

                    {/* STATISTICS ROW 3: Remaining Counts */}
                    <tr className="bg-slate-50 h-8 font-bold">
                      <td className="bg-slate-100 border-r border-b border-slate-200 sticky left-0 z-20 text-center text-[9px] font-mono font-black text-slate-400 select-none">
                        ✗
                      </td>
                      <td className="bg-slate-100 border-r border-b border-slate-200 sticky left-[40px] z-20 px-3 text-[10px] text-slate-500 font-mono tracking-tight font-black">
                        Remaining (Unchecked)
                      </td>
                      {daysInMonth.map(day => {
                        let completedCount = 0;
                        habits.forEach(h => {
                          if (h.done[day.dateKey]) completedCount++;
                        });
                        const remaining = habits.length - completedCount;
                        return (
                          <td key={`prog-rem-${day.dateKey}`} className={`border-r border-b border-slate-200 text-center font-mono text-xs text-rose-500 ${
                            day.isWeekend ? 'bg-slate-100/70' : 'bg-slate-50'
                          }`}>
                            {remaining}
                          </td>
                        );
                      })}
                      {/* Analysis Column Placeholders */}
                      <td colSpan={3} className="bg-slate-100 border-b border-slate-200" />
                    </tr>

                  </tbody>
                </table>
              </div>

            </div>
          </div>
        )}

        {/* VIEW 2: DAILY DONUT DASHBOARD */}
        {activeTab === 'dashboard' && (
          <div className="flex-1 flex flex-col overflow-hidden p-6 gap-6">
            
            {/* Top dashboard control bar */}
            <div className="flex items-center justify-between shrink-0 bg-white border border-slate-200 rounded-xl p-4 shadow-sm">
              <div className="flex items-center gap-4">
                <div className="flex flex-col gap-0.5">
                  <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Dashboard Navigation</span>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => {
                        const newD = new Date(currentWeekStart);
                        newD.setDate(currentWeekStart.getDate() - 7);
                        setCurrentWeekStart(newD);
                      }}
                      className="flex items-center gap-1 px-2.5 py-1.5 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-[11px] font-bold text-slate-600 transition-colors"
                    >
                      <Icons.ArrowLeft className="w-3.5 h-3.5" />
                      <span>Prev Week</span>
                    </button>
                    
                    <span className="text-xs font-mono font-bold text-slate-700 px-2 select-text">
                      {currentWeekStart.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
                      {' - '}
                      {(() => {
                        const end = new Date(currentWeekStart);
                        end.setDate(currentWeekStart.getDate() + 6);
                        return end.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
                      })()}
                    </span>

                    <button
                      onClick={() => {
                        const newD = new Date(currentWeekStart);
                        newD.setDate(currentWeekStart.getDate() + 7);
                        setCurrentWeekStart(newD);
                      }}
                      className="flex items-center gap-1 px-2.5 py-1.5 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-[11px] font-bold text-slate-600 transition-colors"
                    >
                      <span>Next Week</span>
                      <Icons.ArrowRight className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                <div className="h-8 w-px bg-slate-200" />

                {/* Overall completion bar */}
                <div className="flex items-center gap-4 bg-[#f8fafc] border border-slate-200/60 rounded-lg px-4 py-1.5">
                  <div className="flex flex-col">
                    <span className="text-[9px] text-slate-400 font-bold uppercase tracking-wider font-mono">Completed Target</span>
                    <span className="text-sm font-black text-slate-800 leading-none mt-0.5">{weeklyOverallStats.completed} / {weeklyOverallStats.possible} Completed</span>
                  </div>
                  <div className="flex flex-col w-32">
                    <span className="text-[8px] text-slate-400 font-bold uppercase tracking-wider mb-1">Weekly completion pct</span>
                    <div className="w-full bg-slate-200 h-2.5 rounded-full overflow-hidden border border-slate-300/40">
                      <div className="bg-[#22c55e] h-full transition-all duration-700" style={{ width: `${weeklyOverallStats.pct}%` }} />
                    </div>
                  </div>
                  <span className="text-xs font-mono font-bold text-[#13854e]">{weeklyOverallStats.pct}%</span>
                </div>
              </div>

              <div className="text-[10px] text-slate-400 font-mono font-semibold">
                Excel view: columns C:I
              </div>
            </div>

            {/* Main dashboard list columns scrollable */}
            <div className="flex-1 overflow-x-auto custom-scrollbar flex gap-5 pb-4 select-none">
              
              {dashboardWeekDays.map(day => (
                <div
                  key={day.dateKey}
                  className="w-[220px] bg-white border border-slate-200 rounded-xl shadow-sm flex flex-col overflow-hidden shrink-0"
                >
                  {/* Day Date Header Box (Green banner) */}
                  <div className="bg-[#e2f0d9] border-b border-slate-200 p-3 flex flex-col items-center justify-center shrink-0">
                    <span className="text-xs font-black text-slate-800 leading-none">{day.dayName}</span>
                    <span className="text-[9px] text-slate-500 font-mono font-semibold mt-1">{day.dateStr}</span>
                  </div>

                  {/* Circular progress display */}
                  <div className="p-4 border-b border-slate-100 flex items-center justify-center shrink-0">
                    <DonutChart percentage={day.pct} />
                  </div>

                  {/* Tasks list checklist block */}
                  <div className="flex-1 overflow-y-auto p-3 flex flex-col gap-2 bg-[#fcfdfc]">
                    <div className="text-[9px] font-black text-slate-400 uppercase tracking-widest px-1 shrink-0">
                      Tasks List
                    </div>
                    
                    <div className="flex flex-col gap-1.5">
                      {habits.map(habit => {
                        const isChecked = !!habit.done[day.dateKey];
                        return (
                          <div
                            key={`${day.dateKey}-${habit.id}`}
                            onClick={() => handleToggleDone(habit.id, day.dateKey)}
                            className={`p-2 rounded-lg border flex items-start gap-2.5 cursor-pointer transition-all ${
                              isChecked
                                ? 'bg-slate-50 border-slate-200/80 text-slate-400'
                                : 'bg-white hover:bg-slate-50/50 border-slate-200 text-slate-700'
                            }`}
                          >
                            {/* Checkbox square */}
                            <div className={`w-3.5 h-3.5 rounded border shrink-0 mt-0.5 flex items-center justify-center transition-all ${
                              isChecked
                                ? 'bg-slate-800 border-slate-800 text-white'
                                : 'border-slate-300 bg-white'
                            }`}>
                              {isChecked && <Icons.Check className="w-2.5 h-2.5 stroke-[3]" />}
                            </div>
                            
                            {/* Task item label */}
                            <div className="flex flex-col leading-tight select-none">
                              <span className={`text-[11px] font-bold break-words leading-tight ${isChecked ? 'line-through text-slate-400 font-normal' : 'text-slate-800 font-medium'}`}>
                                {habit.name} {habit.emoji}
                              </span>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>
              ))}

            </div>
          </div>
        )}

        {/* VIEW 3: CONFIGURE/MANAGE HABITS */}
        {activeTab === 'manage' && (
          <div className="flex-1 overflow-y-auto custom-scrollbar p-8 max-w-4xl mx-auto w-full flex flex-col gap-6">
            <div className="flex items-center justify-between border-b border-slate-200 pb-4 shrink-0">
              <div>
                <h2 className="text-base font-bold text-slate-900 leading-none">Habit Configuration Manager</h2>
                <p className="text-xs text-slate-400 mt-1">Add, update, or remove habits, customized goal counts and emoji icons.</p>
              </div>
              <button
                onClick={() => openModal()}
                className="flex items-center gap-1 px-3.5 py-1.5 bg-[#13854e] hover:bg-[#0f6c3e] text-white rounded-lg text-xs font-bold shadow-sm transition-all"
              >
                <Icons.Plus className="w-4 h-4" />
                <span>Establish Habit</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {habits.map(habit => {
                // Count completions
                const totalCheckins = Object.values(habit.done).filter(Boolean).length;
                const { current } = calculateStreak(habit.done);

                return (
                  <div
                    key={habit.id}
                    className="bg-white border border-slate-200 rounded-xl p-4 flex flex-col justify-between gap-4 shadow-sm hover:border-[#13854e]/50 transition-all group"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center text-xl shadow-inner shrink-0 border border-slate-200/50 select-none">
                          {habit.emoji || '⭐'}
                        </div>
                        <div>
                          <h3 className="text-xs font-black text-slate-800 leading-none leading-tight">{habit.name}</h3>
                          <span className="text-[9px] font-mono text-slate-400 font-bold uppercase tracking-wider mt-1.5 block">
                            Target Goal: {habit.goalDays || 30} Completed Days / month
                          </span>
                        </div>
                      </div>

                      <span className="text-[9px] font-bold px-2 py-0.5 rounded bg-slate-100 border border-slate-200 text-slate-500 uppercase tracking-wide">
                        {CATS[habit.cat]?.name || 'Routine'}
                      </span>
                    </div>

                    {habit.description && (
                      <p className="text-[10px] text-slate-500 font-medium bg-slate-50 border border-slate-100 p-2.5 rounded-lg">
                        {habit.description}
                      </p>
                    )}

                    <div className="flex items-center justify-between bg-slate-50/50 p-2 px-3 border border-slate-100 rounded-lg text-[10px] font-bold">
                      <span className="text-slate-500 font-mono">Completions: {totalCheckins} days</span>
                      <span className="text-[#13854e] font-mono flex items-center gap-0.5">
                        🔥 Streak: {current} days
                      </span>
                    </div>

                    <div className="flex justify-end gap-2 border-t border-slate-100 pt-3">
                      <button
                        onClick={() => openModal(habit)}
                        className="flex items-center gap-1 px-3 py-1.5 bg-slate-50 hover:bg-slate-100 text-slate-600 hover:text-slate-800 border border-slate-200 rounded-lg text-[11px] font-bold transition-all cursor-pointer"
                      >
                        <Icons.Edit className="w-3 h-3" />
                        <span>Edit</span>
                      </button>
                      <button
                        onClick={() => {
                          if (confirm(`Are you sure you want to remove "${habit.name}"?`)) {
                            deleteHabit(habit.id);
                            setToast({ message: 'Habit deleted successfully' });
                          }
                        }}
                        className="flex items-center gap-1 px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-600 hover:text-rose-700 border border-rose-100 rounded-lg text-[11px] font-bold transition-all cursor-pointer"
                      >
                        <Icons.Trash2 className="w-3 h-3" />
                        <span>Delete</span>
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

      </div>

      {/* MODAL: ADD / EDIT HABIT */}
      {isModalOpen && (
        <div className="fixed inset-0 z-[200] flex items-center justify-center bg-black/50 backdrop-blur-xs p-4 animate-in fade-in duration-200">
          <div className="bg-white border border-slate-200 w-full max-w-[420px] rounded-2xl overflow-hidden shadow-2xl animate-in zoom-in-95 duration-200 flex flex-col">
            
            {/* Modal Header */}
            <div className="flex items-center justify-between p-4 border-b border-slate-100 shrink-0">
              <h2 className="text-xs font-black text-slate-800 uppercase tracking-widest flex items-center gap-1.5">
                {editingHabit ? <Icons.Edit className="w-4 h-4 text-[#13854e]" /> : <Icons.PlusCircle className="w-4 h-4 text-[#13854e]" />}
                <span>{editingHabit ? 'Modify Habit details' : 'Establish New Habit'}</span>
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-slate-700 transition-colors cursor-pointer"
              >
                <Icons.X className="w-4.5 h-4.5" />
              </button>
            </div>

            {/* Modal Form */}
            <form onSubmit={handleSaveForm} className="p-5 flex flex-col gap-4 overflow-y-auto max-h-[75vh] custom-scrollbar">
              
              {/* Habit Name */}
              <div className="flex flex-col gap-1.5">
                <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Habit Name</label>
                <input
                  type="text"
                  required
                  autoFocus
                  placeholder="e.g. Wake up at 05:00"
                  value={habitName}
                  onChange={(e) => setHabitName(e.target.value)}
                  className="border border-slate-300 rounded-lg px-3 py-2 text-xs outline-none focus:border-[#13854e] focus:ring-1 focus:ring-[#13854e] w-full text-slate-800"
                />
              </div>

              {/* Description */}
              <div className="flex flex-col gap-1.5">
                <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Description</label>
                <textarea
                  placeholder="Details of the routine..."
                  value={habitDesc}
                  onChange={(e) => setHabitDesc(e.target.value)}
                  rows={2}
                  className="border border-slate-300 rounded-lg px-3 py-2 text-xs outline-none focus:border-[#13854e] focus:ring-1 focus:ring-[#13854e] w-full resize-none text-slate-800"
                />
              </div>

              {/* Target Goal (Days completed / month) */}
              <div className="flex flex-col gap-1.5">
                <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Monthly Target (Goal Days)</label>
                <input
                  type="number"
                  min={1}
                  max={31}
                  required
                  placeholder="30"
                  value={habitGoal}
                  onChange={(e) => setHabitGoal(Number(e.target.value))}
                  className="border border-slate-300 rounded-lg px-3 py-2 text-xs outline-none focus:border-[#13854e] focus:ring-1 focus:ring-[#13854e] w-full font-mono text-slate-800"
                />
                <span className="text-[8px] text-slate-400 italic">Ideal target for completions within a month</span>
              </div>

              {/* Emoji alignment */}
              <div className="flex flex-col gap-2">
                <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Choose Emoji / Badge</label>
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-xl bg-slate-100 flex items-center justify-center text-2xl border border-slate-200">
                    {habitEmoji}
                  </div>
                  <input
                    type="text"
                    maxLength={2}
                    value={habitEmoji}
                    onChange={(e) => setHabitEmoji(e.target.value)}
                    className="border border-slate-300 rounded-lg px-2 py-1 text-xs outline-none focus:border-[#13854e] w-14 text-center font-bold text-slate-800"
                  />
                  <span className="text-[9px] text-slate-400">Custom character or emoji</span>
                </div>
                
                {/* Popular emojis quick picker */}
                <div className="grid grid-cols-8 gap-2 bg-slate-50 p-2.5 rounded-lg border border-slate-100">
                  {POPULAR_EMOJIS.map(emoji => (
                    <button
                      key={emoji}
                      type="button"
                      onClick={() => setHabitEmoji(emoji)}
                      className={`text-lg p-1 hover:bg-slate-200 rounded transition-all select-none cursor-pointer ${
                        habitEmoji === emoji ? 'bg-slate-200 border border-slate-300' : ''
                      }`}
                    >
                      {emoji}
                    </button>
                  ))}
                </div>
              </div>

              {/* Category */}
              <div className="flex flex-col gap-1.5">
                <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Category Allocation</label>
                <div className="grid grid-cols-3 gap-2">
                  {CATS.map((cat, i) => {
                    const isActive = habitCat === i;
                    return (
                      <button
                        key={cat.name}
                        type="button"
                        onClick={() => setHabitCat(i)}
                        className={`py-2 rounded-lg border text-[10px] font-bold transition-all cursor-pointer ${
                          isActive
                            ? 'bg-[#e2f0d9] border-[#13854e] text-slate-850'
                            : 'bg-white border-slate-200 text-slate-500 hover:bg-slate-50'
                        }`}
                      >
                        <span>{cat.name}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Modal buttons */}
              <div className="flex gap-2.5 mt-4 pt-4 border-t border-slate-100 shrink-0">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 py-2 border border-slate-300 rounded-lg text-slate-500 hover:text-slate-700 text-xs font-bold bg-white hover:bg-slate-50 transition-colors cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2 rounded-lg bg-[#13854e] hover:bg-[#0f6c3e] text-white text-xs font-bold shadow-sm transition-all active:scale-[0.98] cursor-pointer"
                >
                  {editingHabit ? 'Save Changes' : 'Establish'}
                </button>
              </div>

            </form>
          </div>
        </div>
      )}

      {/* Global CSS scrollbar styling */}
      <style jsx global>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 5px;
          height: 5px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: transparent;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: #cbd5e1;
          border-radius: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: #94a3b8;
        }
      `}</style>

    </div>
  );
}
