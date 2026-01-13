//
//  HabitCardView.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI
import SwiftData

/// 习惯卡片视图（带滑动手势）
struct HabitCardView: View {
    @Bindable var habit: Habit
    let selectedDate: Date
    var onTap: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var timerService: TimerService
    
    // 滑动状态
    @State private var sliderValue: Double = 0
    @State private var isDragging: Bool = false
    @State private var dragStartValue: Double = 0
    @State private var showingSliderOverlay: Bool = false
    
    // 计算属性
    private var habitColor: Color { Color(hex: habit.colorHex) }
    private var currentLog: HabitLog? { habit.log(for: selectedDate) }
    private var currentValue: Double { currentLog?.valueLogged ?? 0 }
    private var completionRate: Double { habit.completionRate(for: selectedDate) }
    private var isCompleted: Bool { completionRate >= 1.0 }
    
    var body: some View {
        ZStack {
            // 背景进度
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(habitColor.opacity(0.15))
                        .frame(width: geometry.size.width * min(completionRate, 1.0))
                    Spacer(minLength: 0)
                }
            }
            
            // 内容
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: habit.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(habitColor)
                }
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(Color.AppColors.textPrimary)
                        .strikethrough(isCompleted, color: Color.AppColors.textSecondary)
                    
                    HStack(spacing: 4) {
                        Text("\(Int(currentValue))")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(habitColor)
                        
                        Text("/ \(Int(habit.goalAmount)) \(habit.unit.rawValue)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Color.AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // 操作按钮区域
                HStack(spacing: 12) {
                    // 计时按钮（仅时间类习惯）
                    if habit.isTimeBased {
                        TimerButton(habit: habit)
                    }
                    
                    // 滑动区域 / 快速添加按钮
                    SliderArea(
                        habit: habit,
                        currentValue: currentValue,
                        sliderValue: $sliderValue,
                        isDragging: $isDragging,
                        onValueChange: { newValue in
                            updateHabitLog(value: newValue)
                        }
                    )
                }
            }
            .padding(16)
        }
        .frame(height: 88)
        .tiimoCard(cornerRadius: 24)
        .onTapGesture {
            onTap()
        }
        .animation(.spring(response: 0.3), value: completionRate)
    }
    
    // MARK: - Methods
    
    private func updateHabitLog(value: Double) {
        if let log = currentLog {
            log.valueLogged = value
            log.updatedAt = Date()
        } else {
            let newLog = HabitLog(date: selectedDate, valueLogged: value)
            newLog.habit = habit
            modelContext.insert(newLog)
        }
        
        // 触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Timer Button

struct TimerButton: View {
    let habit: Habit
    @EnvironmentObject var timerService: TimerService
    
    private var isRunning: Bool {
        if case .habit(let id) = timerService.currentTimerType {
            return id == habit.id && timerService.timerState == .running
        }
        return false
    }
    
    var body: some View {
        Button {
            if isRunning {
                timerService.pauseCurrentTimer()
            } else {
                timerService.startHabitTimer(
                    habitId: habit.id,
                    title: habit.title,
                    colorHex: habit.colorHex,
                    targetDuration: habit.goalAmount * 60
                )
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: habit.colorHex))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slider Area

struct SliderArea: View {
    let habit: Habit
    let currentValue: Double
    @Binding var sliderValue: Double
    @Binding var isDragging: Bool
    var onValueChange: (Double) -> Void
    
    @State private var dragStartX: CGFloat = 0
    
    private var displayValue: Double {
        isDragging ? sliderValue : currentValue
    }
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: habit.colorHex).opacity(isDragging ? 0.3 : 0.15))
                .frame(width: 70, height: 44)
            
            if isDragging {
                // 拖动时显示数值
                Text("\(Int(sliderValue))")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(Color(hex: habit.colorHex))
            } else {
                // 默认显示加号
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: habit.colorHex))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragStartX = value.location.x
                        sliderValue = currentValue
                    }
                    
                    let dragDistance = value.location.x - dragStartX
                    let increment = dragDistance / 15 // 每 15 点增加 1
                    sliderValue = max(0, currentValue + increment)
                    
                    // 震动反馈
                    if Int(sliderValue) != Int(currentValue + increment - (dragDistance / 15).truncatingRemainder(dividingBy: 1) * 15 / 15) {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                    }
                }
                .onEnded { _ in
                    onValueChange(sliderValue.rounded())
                    isDragging = false
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    // 快速 +1
                    onValueChange(currentValue + 1)
                }
        )
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitLog.self, configurations: config)
    
    let habit = Habit(
        title: "喝水",
        iconName: "drop.fill",
        colorHex: "#74B9FF",
        goalAmount: 8,
        unit: .glasses
    )
    container.mainContext.insert(habit)
    
    return HabitCardView(habit: habit, selectedDate: Date()) {}
        .padding()
        .modelContainer(container)
        .environmentObject(TimerService.shared)
}
