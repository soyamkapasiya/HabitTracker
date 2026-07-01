'use client';

import { useState, useEffect } from 'react';

export interface Habit {
  id: string;
  name: string;
  cat: number; // Index of category in CATS
  frequency: 'daily' | 'weekly';
  description?: string;
  createdAt: string;
  done: Record<string, boolean>; // key: "YYYY-MM-DD", value: true (completed)
  emoji?: string;
  goalDays?: number; // target number of completed days in the month/cycle
}

export const CATS = [
  { name: 'Fitness', color: '#10b981', icon: 'Dumbbell' },
  { name: 'Reading', color: '#3b82f6', icon: 'BookOpen' },
  { name: 'Wellness', color: '#8b5cf6', icon: 'Sparkles' },
  { name: 'Productivity', color: '#f59e0b', icon: 'Briefcase' },
  { name: 'Health', color: '#ef4444', icon: 'Heart' },
  { name: 'Mindset', color: '#ec4899', icon: 'Brain' }
];

const STORAGE_KEY = 'dailyHabitTrackerData_v2';

// Helper to get formatted date string (YYYY-MM-DD)
export function getLocalDateString(date: Date = new Date()): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Helper to calculate streaks
export function calculateStreak(done: Record<string, boolean>): { current: number; max: number } {
  const dates = Object.keys(done)
    .filter(k => done[k])
    .sort((a, b) => new Date(b).getTime() - new Date(a).getTime());

  if (dates.length === 0) {
    return { current: 0, max: 0 };
  }

  // Calculate current streak
  let currentStreak = 0;
  const todayStr = getLocalDateString(new Date());
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = getLocalDateString(yesterday);

  // If today or yesterday is completed, start counting
  const hasCompletedToday = !!done[todayStr];
  const hasCompletedYesterday = !!done[yesterdayStr];

  if (hasCompletedToday || hasCompletedYesterday) {
    let checkDate = hasCompletedToday ? new Date() : yesterday;
    while (true) {
      const checkStr = getLocalDateString(checkDate);
      if (done[checkStr]) {
        currentStreak++;
        checkDate.setDate(checkDate.getDate() - 1);
      } else {
        break;
      }
    }
  }

  // Calculate max/best streak
  const sortedDatesAsc = Object.keys(done)
    .filter(k => done[k])
    .sort((a, b) => new Date(a).getTime() - new Date(b).getTime());

  let maxStreak = 0;
  let tempStreak = 0;
  let prevTime: number | null = null;

  for (const dateStr of sortedDatesAsc) {
    const currTime = new Date(dateStr).getTime();
    if (prevTime === null) {
      tempStreak = 1;
    } else {
      const diffDays = Math.round((currTime - prevTime) / (1000 * 60 * 60 * 24));
      if (diffDays === 1) {
        tempStreak++;
      } else if (diffDays > 1) {
        maxStreak = Math.max(maxStreak, tempStreak);
        tempStreak = 1;
      }
    }
    prevTime = currTime;
  }
  maxStreak = Math.max(maxStreak, tempStreak);

  return { current: currentStreak, max: maxStreak };
}

export function useUltimateHabitTracker() {
  const [habits, setHabits] = useState<Habit[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        const parsed = JSON.parse(stored) as Habit[];
        // Add defaults if migrating from older schema
        const migrated = parsed.map((h, idx) => ({
          ...h,
          emoji: h.emoji || ['⏰', '💪', '🔞', '📖', '💰', '🎯', '🚫', '🌿', '📒', '🚿'][idx % 10],
          goalDays: h.goalDays || 30
        }));
        setHabits(migrated);
      } catch (e) {
        console.error('Failed to parse habits:', e);
        setHabits(getInitialHabits());
      }
    } else {
      setHabits(getInitialHabits());
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    if (!loading) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(habits));
    }
  }, [habits, loading]);

  const getInitialHabits = (): Habit[] => {
    const today = new Date();
    const oldestDate = new Date();
    oldestDate.setDate(today.getDate() - 30);
    const oldestStr = getLocalDateString(oldestDate);

    const list: Habit[] = [
      { id: '1', name: 'Wake up at 05:00', cat: 4, frequency: 'daily', description: 'Wake up early to seize the day.', createdAt: oldestStr, done: {}, emoji: '⏰', goalDays: 30 },
      { id: '2', name: 'Gym', cat: 0, frequency: 'daily', description: 'Strength or cardio workout.', createdAt: oldestStr, done: {}, emoji: '💪', goalDays: 30 },
      { id: '3', name: 'Stop Watching Porn', cat: 2, frequency: 'daily', description: 'Avoid triggers, maintain mental clarity.', createdAt: oldestStr, done: {}, emoji: '🔞', goalDays: 30 },
      { id: '4', name: 'Reading / Learning', cat: 1, frequency: 'daily', description: 'Read non-fiction, articles, or learn a skill.', createdAt: oldestStr, done: {}, emoji: '📖', goalDays: 30 },
      { id: '5', name: 'Budget Tracking', cat: 3, frequency: 'daily', description: 'Log all expenses and stay within budget.', createdAt: oldestStr, done: {}, emoji: '💰', goalDays: 30 },
      { id: '6', name: 'Project Work', cat: 3, frequency: 'daily', description: 'Focus time on development or writing.', createdAt: oldestStr, done: {}, emoji: '🎯', goalDays: 30 },
      { id: '7', name: 'No Alcohol', cat: 4, frequency: 'daily', description: 'Avoid alcoholic beverages completely.', createdAt: oldestStr, done: {}, emoji: '🚫', goalDays: 30 },
      { id: '8', name: 'Social Media Detox', cat: 2, frequency: 'daily', description: 'Restrict mindless scrolling.', createdAt: oldestStr, done: {}, emoji: '🌿', goalDays: 30 },
      { id: '9', name: 'Goal Journaling', cat: 5, frequency: 'daily', description: 'Review goals and write thoughts.', createdAt: oldestStr, done: {}, emoji: '📒', goalDays: 30 },
      { id: '10', name: 'Cold Shower', cat: 2, frequency: 'daily', description: 'Kickstart circulation and alertness.', createdAt: oldestStr, done: {}, emoji: '🚿', goalDays: 30 }
    ];

    // Seed data actual targets matching the screenshot:
    // Actual: [16, 25, 27, 27, 24, 24, 25, 20, 29, 30]
    const targetActuals = [16, 25, 27, 27, 24, 24, 25, 20, 29, 30];

    list.forEach((habit, idx) => {
      const actualCount = targetActuals[idx];
      const daysIndices = Array.from({ length: 30 }, (_, i) => i);
      
      // Shuffle indices based on habit index to make distributions unique but reproducible
      if (actualCount < 30) {
        for (let i = daysIndices.length - 1; i > 0; i--) {
          const j = (idx * 11 + i * 7) % (i + 1);
          [daysIndices[i], daysIndices[j]] = [daysIndices[j], daysIndices[i]];
        }
      }

      const selectedIndices = new Set(daysIndices.slice(0, actualCount));

      for (let d = 1; d <= 30; d++) {
        const date = new Date();
        date.setDate(today.getDate() - d);
        const dateStr = getLocalDateString(date);
        
        if (selectedIndices.has(d - 1)) {
          habit.done[dateStr] = true;
        }
      }
    });

    return list;
  };

  const toggleDone = (habitId: string, dateKey: string) => {
    setHabits(prev => prev.map(h => {
      if (h.id === habitId) {
        const newDone = { ...h.done };
        if (newDone[dateKey]) {
          delete newDone[dateKey];
        } else {
          newDone[dateKey] = true;
        }
        return { ...h, done: newDone };
      }
      return h;
    }));
  };

  const addHabit = (
    name: string,
    cat: number,
    frequency: 'daily' | 'weekly' = 'daily',
    description: string = '',
    emoji: string = '⭐',
    goalDays: number = 30
  ) => {
    const newHabit: Habit = {
      id: Date.now().toString(),
      name,
      cat,
      frequency,
      description,
      createdAt: getLocalDateString(),
      done: {},
      emoji,
      goalDays
    };
    setHabits(prev => [...prev, newHabit]);
  };

  const updateHabit = (
    id: string,
    name: string,
    cat: number,
    frequency: 'daily' | 'weekly' = 'daily',
    description: string = '',
    emoji: string = '⭐',
    goalDays: number = 30
  ) => {
    setHabits(prev => prev.map(h => h.id === id ? { ...h, name, cat, frequency, description, emoji, goalDays } : h));
  };

  const deleteHabit = (id: string) => {
    setHabits(prev => prev.filter(h => h.id !== id));
  };

  return {
    habits,
    loading,
    toggleDone,
    addHabit,
    updateHabit,
    deleteHabit,
  };
}
