//
//  PomodoroView.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI
import SwiftData

/// 番茄钟主视图
struct PomodoroView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PomodoroSession.startTime, order: .reverse) private var sessions: [PomodoroSession]
    @EnvironmentObject var timerService: TimerService
    
    @State private var selectedDuration: TimeInterval = 30 * 60 // 30分钟
    @State private var showingHistory = false
    @State private var pomodoroLabel: String = ""
    
    // 是否正在进行番茄钟
    private var isActive: Bool {
        timerService.currentTimerType == .pomodoro && timerService.timerState.isActive
    }
    
    private var isRunning: Bool {
        timerService.currentTimerType == .pomodoro && timerService.timerState == .running
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color.AppColors.coral.opacity(0.1),
                        Color.AppColors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // 圆形时钟拨盘
                    CircularTimerDial(
                        duration: isActive ? timerService.targetDuration : selectedDuration,
                        elapsed: isActive ? timerService.elapsedTime : 0,
                        remaining: isActive ? timerService.remainingTime : selectedDuration,
                        isActive: isActive,
                        onDurationChange: { newDuration in
                            if !isActive {
                                selectedDuration = newDuration
                            }
                        }
                    )
                    
                    // 时间显示
                    VStack(spacing: 8) {
                        Text(isActive ? timerService.formattedRemainingTime : formatDuration(selectedDuration))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(Color.AppColors.textPrimary)
                        
                        Text(statusText)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color.AppColors.textSecondary)
                    }
                    
                    // 控制按钮
                    controlButtons
                    
                    Spacer()
                    
                    // 历史记录按钮
                    Button {
                        showingHistory = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("历史记录")
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(Color.AppColors.textSecondary)
                    }
                    .padding(.bottom, 100)
                }
                .padding(.horizontal, 40)
            }
            .navigationTitle("专注")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingHistory) {
                PomodoroHistorySheet(sessions: sessions)
            }
            .onReceive(NotificationCenter.default.publisher(for: .pomodoroCompleted)) { _ in
                // 保存完成的番茄钟
                savePomodoroSession(completed: true)
            }
        }
    }
    
    // MARK: - Status Text
    
    private var statusText: String {
        if !isActive {
            return "滑动调整时间"
        } else if isRunning {
            return "专注中..."
        } else {
            return "已暂停"
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 24) {
            if isActive {
                // 停止按钮
                Button {
                    let elapsed = timerService.stopTimer()
                    if elapsed > 60 { // 只保存超过1分钟的会话
                        savePomodoroSession(completed: false)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.AppColors.textTertiary.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "stop.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color.AppColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                // 播放/暂停按钮
                Button {
                    timerService.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.AppColors.coral)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.AppColors.coral.opacity(0.4), radius: 12, y: 4)
                        
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // +1分钟按钮
                Button {
                    timerService.addOneMinute()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.AppColors.coral.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 2) {
                            Text("+1")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            Text("分钟")
                                .font(.system(.caption2, design: .rounded))
                        }
                        .foregroundColor(Color.AppColors.coral)
                    }
                }
                .buttonStyle(.plain)
                .disabled(timerService.targetDuration >= 60 * 60)
            } else {
                // 开始按钮
                Button {
                    timerService.startPomodoro(duration: selectedDuration)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.AppColors.coral)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.AppColors.coral.opacity(0.4), radius: 12, y: 4)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func savePomodoroSession(completed: Bool) {
        let session = PomodoroSession(
            startTime: Date().addingTimeInterval(-timerService.elapsedTime),
            plannedDuration: timerService.targetDuration
        )
        session.actualDuration = timerService.elapsedTime
        session.endTime = Date()
        session.status = completed ? .completed : .interrupted
        
        modelContext.insert(session)
    }
}

// MARK: - Circular Timer Dial

struct CircularTimerDial: View {
    let duration: TimeInterval
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let isActive: Bool
    var onDurationChange: (TimeInterval) -> Void
    
    @State private var dragAngle: Double = 0
    @GestureState private var isDragging = false
    
    private let minDuration: TimeInterval = 5 * 60   // 5分钟
    private let maxDuration: TimeInterval = 60 * 60  // 60分钟
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return elapsed / duration
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = (size - 40) / 2
            
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color.AppColors.coral.opacity(0.15), lineWidth: 20)
                    .frame(width: size - 40, height: size - 40)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.AppColors.coral,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: size - 40, height: size - 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                // 刻度
                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) * 30 - 90
                    let tickLength: CGFloat = i % 3 == 0 ? 15 : 8
                    
                    Rectangle()
                        .fill(Color.AppColors.textTertiary)
                        .frame(width: 2, height: tickLength)
                        .offset(y: -radius + tickLength / 2 + 10)
                        .rotationEffect(.degrees(angle))
                }
                
                // 拖动手柄（仅非活动状态）
                if !isActive {
                    let handleAngle = durationToAngle(duration)
                    
                    Circle()
                        .fill(Color.AppColors.coral)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.AppColors.coral.opacity(0.4), radius: 8)
                        .offset(y: -radius)
                        .rotationEffect(.degrees(handleAngle - 90))
                        .gesture(
                            DragGesture()
                                .updating($isDragging) { _, state, _ in
                                    state = true
                                }
                                .onChanged { value in
                                    let vector = CGVector(
                                        dx: value.location.x - center.x,
                                        dy: value.location.y - center.y
                                    )
                                    let angle = atan2(vector.dy, vector.dx) * 180 / .pi + 90
                                    let normalizedAngle = angle < 0 ? angle + 360 : angle
                                    let newDuration = angleToDuration(normalizedAngle)
                                    onDurationChange(newDuration)
                                }
                        )
                }
                
                // 分钟标签
                ForEach([5, 15, 30, 45, 60], id: \.self) { minute in
                    let angle = durationToAngle(TimeInterval(minute * 60)) - 90
                    
                    Text("\(minute)")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(Color.AppColors.textTertiary)
                        .offset(y: -radius - 25)
                        .rotationEffect(.degrees(angle))
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 300)
    }
    
    private func durationToAngle(_ duration: TimeInterval) -> Double {
        let normalizedDuration = min(max(duration, minDuration), maxDuration)
        return (normalizedDuration / maxDuration) * 360
    }
    
    private func angleToDuration(_ angle: Double) -> TimeInterval {
        let normalizedAngle = min(max(angle, 0), 360)
        let duration = (normalizedAngle / 360) * maxDuration
        // 四舍五入到最近的5分钟
        let roundedMinutes = round(duration / 60 / 5) * 5
        return max(minDuration, min(roundedMinutes * 60, maxDuration))
    }
}

// MARK: - Pomodoro History Sheet

struct PomodoroHistorySheet: View {
    let sessions: [PomodoroSession]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppColors.background
                    .ignoresSafeArea()
                
                if sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(Color.AppColors.textTertiary)
                        
                        Text("暂无历史记录")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundColor(Color.AppColors.textSecondary)
                    }
                } else {
                    List {
                        ForEach(groupedSessions.keys.sorted().reversed(), id: \.self) { date in
                            Section {
                                ForEach(groupedSessions[date] ?? []) { session in
                                    SessionRow(session: session)
                                }
                            } header: {
                                Text(date.relativeDescription)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var groupedSessions: [Date: [PomodoroSession]] {
        Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startTime)
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: PomodoroSession
    
    var body: some View {
        HStack(spacing: 16) {
            // 状态图标
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: session.status.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.label ?? "专注时间")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(Color.AppColors.textPrimary)
                
                HStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.AppColors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(Color.AppColors.textTertiary)
                    
                    Text(session.formattedActualDuration)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // 完成度
            Text("\(Int(session.completionPercentage * 100))%")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch session.status {
        case .completed: return Color.AppColors.success
        case .interrupted: return Color.AppColors.warning
        default: return Color.AppColors.textSecondary
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: session.startTime)
    }
}

// MARK: - Preview

#Preview {
    PomodoroView()
        .modelContainer(for: [PomodoroSession.self], inMemory: true)
        .environmentObject(TimerService.shared)
}
