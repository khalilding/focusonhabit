//
//  ReportView.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI
import SwiftData
import Charts

/// 报告视图时间范围
enum ReportTimeRange: String, CaseIterable {
    case week = "周"
    case month = "月"
    case year = "年"
}

/// 报告主视图
struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    
    @State private var selectedTimeRange: ReportTimeRange = .week
    @State private var selectedHabit: Habit?
    @State private var currentDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 时间范围选择器
                        timeRangePicker
                        
                        // 习惯选择器
                        habitPicker
                        
                        // 统计卡片
                        if let habit = selectedHabit {
                            statsCards(for: habit)
                            
                            // 图表视图
                            chartView(for: habit)
                        } else {
                            overallStatsView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("报告")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Time Range Picker
    
    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(ReportTimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTimeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(selectedTimeRange == range ? .white : Color.AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedTimeRange == range ? Color.AppColors.primary : Color.AppColors.cardBackground)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Habit Picker
    
    private var habitPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部
                Button {
                    selectedHabit = nil
                } label: {
                    Text("全部")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(selectedHabit == nil ? .white : Color.AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedHabit == nil ? Color.AppColors.primary : Color.AppColors.cardBackground)
                        )
                }
                .buttonStyle(.plain)
                
                ForEach(habits.filter { !$0.isArchived }) { habit in
                    Button {
                        selectedHabit = habit
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: habit.iconName)
                                .font(.system(size: 12))
                            Text(habit.title)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                        }
                        .foregroundColor(selectedHabit?.id == habit.id ? .white : Color.AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedHabit?.id == habit.id ? Color(hex: habit.colorHex) : Color.AppColors.cardBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Stats Cards
    
    private func statsCards(for habit: Habit) -> some View {
        let stats = calculateStats(for: habit)
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "完成率",
                value: "\(Int(stats.completionRate * 100))%",
                icon: "chart.pie.fill",
                color: Color(hex: habit.colorHex)
            )
            
            StatCard(
                title: "连续天数",
                value: "\(stats.streak)",
                icon: "flame.fill",
                color: Color.AppColors.coral
            )
            
            StatCard(
                title: "总计完成",
                value: "\(Int(stats.totalValue))",
                icon: "checkmark.circle.fill",
                color: Color.AppColors.mint
            )
            
            StatCard(
                title: "最佳记录",
                value: "\(Int(stats.bestValue))",
                icon: "trophy.fill",
                color: Color.AppColors.sunflower
            )
        }
    }
    
    // MARK: - Chart View
    
    @ViewBuilder
    private func chartView(for habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartTitle)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(Color.AppColors.textPrimary)
            
            switch selectedTimeRange {
            case .week:
                WeekBarChart(habit: habit, currentDate: currentDate)
            case .month:
                MonthHeatmapView(habit: habit, currentDate: currentDate)
            case .year:
                YearHeatmapView(habit: habit, currentDate: currentDate)
            }
        }
        .padding(20)
        .tiimoCard()
    }
    
    private var chartTitle: String {
        switch selectedTimeRange {
        case .week: return "本周数据"
        case .month: return "本月数据"
        case .year: return "年度数据"
        }
    }
    
    // MARK: - Overall Stats View
    
    private var overallStatsView: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "活跃习惯",
                    value: "\(habits.filter { !$0.isArchived }.count)",
                    icon: "leaf.fill",
                    color: Color.AppColors.primary
                )
                
                StatCard(
                    title: "今日完成",
                    value: "\(habits.filter { $0.isCompletedToday() }.count)",
                    icon: "checkmark.circle.fill",
                    color: Color.AppColors.success
                )
            }
            
            // 今日进度
            VStack(alignment: .leading, spacing: 12) {
                Text("今日习惯")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(Color.AppColors.textPrimary)
                
                ForEach(habits.filter { !$0.isArchived && $0.isScheduledForToday() }) { habit in
                    HStack {
                        Image(systemName: habit.iconName)
                            .foregroundColor(Color(hex: habit.colorHex))
                        
                        Text(habit.title)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Color.AppColors.textPrimary)
                        
                        Spacer()
                        
                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: habit.colorHex).opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: habit.colorHex))
                                    .frame(width: geometry.size.width * habit.completionRate(for: Date()))
                            }
                        }
                        .frame(width: 80, height: 8)
                        
                        Text("\(Int(habit.completionRate(for: Date()) * 100))%")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(Color.AppColors.textSecondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(20)
            .tiimoCard()
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateStats(for habit: Habit) -> HabitStats {
        let logs = habit.logs
        let dateRange = getDateRange()
        
        var completedDays = 0
        var totalValue: Double = 0
        var bestValue: Double = 0
        
        for date in dateRange {
            if let log = habit.log(for: date) {
                let rate = habit.completionRate(for: date)
                if rate >= 1.0 {
                    completedDays += 1
                }
                totalValue += log.valueLogged
                bestValue = max(bestValue, log.valueLogged)
            }
        }
        
        let completionRate = dateRange.isEmpty ? 0 : Double(completedDays) / Double(dateRange.count)
        let streak = calculateStreak(for: habit)
        
        return HabitStats(
            completionRate: completionRate,
            streak: streak,
            totalValue: totalValue,
            bestValue: bestValue
        )
    }
    
    private func getDateRange() -> [Date] {
        switch selectedTimeRange {
        case .week:
            return currentDate.weekDates()
        case .month:
            return currentDate.monthDates()
        case .year:
            return currentDate.yearDates()
        }
    }
    
    private func calculateStreak(for habit: Habit) -> Int {
        var streak = 0
        var date = Date()
        
        while true {
            if habit.completionRate(for: date) >= 1.0 {
                streak += 1
                date = date.addingDays(-1)
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Habit Stats

struct HabitStats {
    let completionRate: Double
    let streak: Int
    let totalValue: Double
    let bestValue: Double
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(Color.AppColors.textPrimary)
            
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color.AppColors.textSecondary)
        }
        .padding(16)
        .tiimoCard()
    }
}

// MARK: - Week Bar Chart

struct WeekBarChart: View {
    let habit: Habit
    let currentDate: Date
    
    var body: some View {
        let weekData = getWeekData()
        
        Chart(weekData) { item in
            BarMark(
                x: .value("Day", item.dayName),
                y: .value("Value", item.value)
            )
            .foregroundStyle(Color(hex: habit.colorHex).gradient)
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 200)
    }
    
    private func getWeekData() -> [WeekDataItem] {
        currentDate.weekDates().map { date in
            let value = habit.log(for: date)?.valueLogged ?? 0
            return WeekDataItem(
                dayName: date.shortWeekdayName,
                value: value,
                date: date
            )
        }
    }
}

struct WeekDataItem: Identifiable {
    let id = UUID()
    let dayName: String
    let value: Double
    let date: Date
}

// MARK: - Month Heatmap View

struct MonthHeatmapView: View {
    let habit: Habit
    let currentDate: Date
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 8) {
            // 星期标题
            HStack(spacing: 4) {
                ForEach(Date.shortWeekdayNames, id: \.self) { name in
                    Text(name)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundColor(Color.AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日期格子
            LazyVGrid(columns: columns, spacing: 4) {
                // 填充前面的空白
                ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
                
                ForEach(currentDate.monthDates(), id: \.self) { date in
                    let rate = habit.completionRate(for: date)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cellColor(for: rate))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Text(date.dayString)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(date.isToday ? Color.AppColors.primary : Color.AppColors.textSecondary)
                        )
                }
            }
        }
    }
    
    private var leadingEmptyDays: Int {
        currentDate.startOfMonth.weekdayIndex
    }
    
    private func cellColor(for rate: Double) -> Color {
        if rate == 0 {
            return Color.AppColors.secondaryBackground
        } else if rate < 1.0 {
            return Color(hex: habit.colorHex).opacity(0.3 + rate * 0.4)
        } else {
            return Color(hex: habit.colorHex)
        }
    }
}

// MARK: - Year Heatmap View (GitHub Style)

struct YearHeatmapView: View {
    let habit: Habit
    let currentDate: Date
    
    private let cellSize: CGFloat = 10
    private let spacing: CGFloat = 3
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(getWeeks(), id: \.self) { weekStart in
                    VStack(spacing: spacing) {
                        ForEach(weekDays(from: weekStart), id: \.self) { date in
                            let rate = habit.completionRate(for: date)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(cellColor(for: rate))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .frame(height: (cellSize + spacing) * 7)
    }
    
    private func getWeeks() -> [Date] {
        var weeks: [Date] = []
        var current = currentDate.startOfYear.startOfWeek
        let endDate = currentDate.endOfYear
        
        while current <= endDate {
            weeks.append(current)
            current = current.addingWeeks(1)
        }
        
        return weeks
    }
    
    private func weekDays(from weekStart: Date) -> [Date] {
        (0..<7).map { weekStart.addingDays($0) }
    }
    
    private func cellColor(for rate: Double) -> Color {
        if rate == 0 {
            return Color.AppColors.secondaryBackground
        } else if rate < 0.5 {
            return Color(hex: habit.colorHex).opacity(0.3)
        } else if rate < 1.0 {
            return Color(hex: habit.colorHex).opacity(0.6)
        } else {
            return Color(hex: habit.colorHex)
        }
    }
}

// MARK: - Preview

#Preview {
    ReportView()
        .modelContainer(for: [Habit.self, HabitLog.self], inMemory: true)
}
