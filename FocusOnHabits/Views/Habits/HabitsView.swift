//
//  HabitsView.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI
import SwiftData

/// 习惯主视图
struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @EnvironmentObject var timerService: TimerService
    
    @State private var selectedDate: Date = Date()
    @State private var showingAddHabit = false
    @State private var editingHabit: Habit?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color.AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 周日历
                    WeekCalendarView(selectedDate: $selectedDate)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // 习惯列表
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            // 未完成的习惯
                            ForEach(sortedHabits.filter { !$0.isCompletedToday() }) { habit in
                                HabitCardView(
                                    habit: habit,
                                    selectedDate: selectedDate,
                                    onTap: { editingHabit = habit }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                            
                            // 已完成的习惯
                            if !completedHabits.isEmpty {
                                HStack {
                                    Text("已完成")
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundColor(Color.AppColors.textSecondary)
                                    Spacer()
                                }
                                .padding(.top, 8)
                                
                                ForEach(completedHabits) { habit in
                                    HabitCardView(
                                        habit: habit,
                                        selectedDate: selectedDate,
                                        onTap: { editingHabit = habit }
                                    )
                                    .opacity(0.7)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationTitle("习惯")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(item: $editingHabit) { habit in
                EditHabitView(habit: habit)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var sortedHabits: [Habit] {
        habits.filter { !$0.isArchived && $0.isScheduledForToday() }
    }
    
    private var completedHabits: [Habit] {
        sortedHabits.filter { $0.isCompletedToday() }
    }
}

// MARK: - Week Calendar View

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @State private var weekOffset: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // 月份标题
            HStack {
                Text(currentWeekDates.first?.yearMonthString ?? "")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(Color.AppColors.textPrimary)
                
                Spacer()
                
                // 导航按钮
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            weekOffset -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.AppColors.textSecondary)
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            weekOffset = 0
                            selectedDate = Date()
                        }
                    } label: {
                        Text("今天")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(Color.AppColors.primary)
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            weekOffset += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.AppColors.textSecondary)
                    }
                }
            }
            
            // 日期选择
            HStack(spacing: 8) {
                ForEach(currentWeekDates, id: \.self) { date in
                    DayButton(
                        date: date,
                        isSelected: date.isSameDay(as: selectedDate),
                        isToday: date.isToday
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.AppColors.cardBackground)
        )
    }
    
    private var currentWeekDates: [Date] {
        Date().addingWeeks(weekOffset).weekDates()
    }
}

/// 日期按钮
struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(Date.shortWeekdayNames[date.weekdayIndex])
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.AppColors.textTertiary)
                
                Text(date.dayString)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(isSelected ? .white : (isToday ? Color.AppColors.primary : Color.AppColors.textPrimary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.AppColors.primary : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isToday && !isSelected ? Color.AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HabitsView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
        .environmentObject(TimerService.shared)
}
