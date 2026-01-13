//
//  TimerService.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import Foundation
import SwiftUI
import ActivityKit
import Combine

/// 计时器类型
enum TimerType: Equatable {
    case habit(habitId: UUID)
    case task(taskId: UUID)
    case pomodoro
    
    var displayName: String {
        switch self {
        case .habit: return "习惯计时"
        case .task: return "任务计时"
        case .pomodoro: return "番茄钟"
        }
    }
    
    var icon: String {
        switch self {
        case .habit: return "leaf.fill"
        case .task: return "checkmark.circle.fill"
        case .pomodoro: return "timer"
        }
    }
}

/// 计时器状态
enum TimerState: Equatable {
    case idle
    case running
    case paused
    
    var isActive: Bool {
        self == .running || self == .paused
    }
}

/// 全局计时器服务 - 单例模式
/// 确保同一时间只有一个计时器在运行
@MainActor
final class TimerService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = TimerService()
    
    // MARK: - Published Properties
    
    /// 当前计时器类型
    @Published private(set) var currentTimerType: TimerType?
    
    /// 当前计时器状态
    @Published private(set) var timerState: TimerState = .idle
    
    /// 已用时间（秒）
    @Published private(set) var elapsedTime: TimeInterval = 0
    
    /// 目标时间（秒，用于番茄钟）
    @Published private(set) var targetDuration: TimeInterval = 30 * 60 // 默认30分钟
    
    /// 剩余时间（用于倒计时模式）
    @Published private(set) var remainingTime: TimeInterval = 0
    
    /// 当前显示的标题
    @Published private(set) var currentTitle: String = ""
    
    /// 当前颜色
    @Published private(set) var currentColorHex: String = "#6C5CE7"
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var startDate: Date?
    private var pausedElapsedTime: TimeInterval = 0
    private var cancellables = Set<AnyCancellable>()
    
    /// Live Activity
    private var currentActivity: Activity<FocusTimerAttributes>?
    
    // MARK: - Computed Properties
    
    /// 格式化的已用时间
    var formattedElapsedTime: String {
        formatTime(elapsedTime)
    }
    
    /// 格式化的剩余时间
    var formattedRemainingTime: String {
        formatTime(remainingTime)
    }
    
    /// 进度百分比
    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(elapsedTime / targetDuration, 1.0)
    }
    
    /// 是否为倒计时模式
    var isCountdownMode: Bool {
        currentTimerType == .pomodoro
    }
    
    // MARK: - Initialization
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// 开始习惯计时
    func startHabitTimer(
        habitId: UUID,
        title: String,
        colorHex: String,
        targetDuration: TimeInterval? = nil
    ) {
        // 如果有其他计时器在运行，先暂停
        if timerState == .running {
            pauseCurrentTimer()
        }
        
        // 重置状态
        resetTimer()
        
        currentTimerType = .habit(habitId: habitId)
        currentTitle = title
        currentColorHex = colorHex
        
        if let target = targetDuration {
            self.targetDuration = target
            self.remainingTime = target
        }
        
        startTimer()
        startLiveActivity()
    }
    
    /// 开始任务计时
    func startTaskTimer(
        taskId: UUID,
        title: String,
        colorHex: String
    ) {
        // 如果有其他计时器在运行，先暂停
        if timerState == .running {
            pauseCurrentTimer()
        }
        
        // 重置状态
        resetTimer()
        
        currentTimerType = .task(taskId: taskId)
        currentTitle = title
        currentColorHex = colorHex
        self.targetDuration = 0 // 任务计时没有目标
        
        startTimer()
        startLiveActivity()
    }
    
    /// 开始番茄钟
    func startPomodoro(duration: TimeInterval = 30 * 60, title: String = "专注时间") {
        // 如果有其他计时器在运行，先暂停
        if timerState == .running {
            pauseCurrentTimer()
        }
        
        // 重置状态
        resetTimer()
        
        currentTimerType = .pomodoro
        currentTitle = title
        currentColorHex = "#FF6B6B"
        targetDuration = duration
        remainingTime = duration
        
        startTimer()
        startLiveActivity()
    }
    
    /// 暂停当前计时器
    func pauseCurrentTimer() {
        guard timerState == .running else { return }
        
        timer?.invalidate()
        timer = nil
        timerState = .paused
        pausedElapsedTime = elapsedTime
        
        updateLiveActivity()
    }
    
    /// 恢复计时器
    func resumeTimer() {
        guard timerState == .paused else { return }
        
        startDate = Date()
        startTimer()
        
        updateLiveActivity()
    }
    
    /// 停止计时器
    func stopTimer() -> TimeInterval {
        let finalTime = elapsedTime
        
        timer?.invalidate()
        timer = nil
        
        endLiveActivity()
        resetTimer()
        
        return finalTime
    }
    
    /// 为番茄钟增加1分钟（最大60分钟）
    func addOneMinute() {
        guard currentTimerType == .pomodoro else { return }
        
        let maxDuration: TimeInterval = 60 * 60 // 60分钟
        let newTarget = min(targetDuration + 60, maxDuration)
        let addedTime = newTarget - targetDuration
        
        targetDuration = newTarget
        remainingTime += addedTime
        
        updateLiveActivity()
    }
    
    /// 切换播放/暂停
    func togglePlayPause() {
        switch timerState {
        case .idle:
            // 什么都不做，需要先调用 start 方法
            break
        case .running:
            pauseCurrentTimer()
        case .paused:
            resumeTimer()
        }
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        startDate = Date()
        timerState = .running
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func tick() {
        guard let startDate = startDate else { return }
        
        let currentElapsed = Date().timeIntervalSince(startDate) + pausedElapsedTime
        elapsedTime = currentElapsed
        
        if isCountdownMode {
            remainingTime = max(targetDuration - elapsedTime, 0)
            
            // 番茄钟完成
            if remainingTime <= 0 {
                completePomodoro()
            }
        }
    }
    
    private func completePomodoro() {
        _ = stopTimer()
        // 发送完成通知
        NotificationCenter.default.post(
            name: .pomodoroCompleted,
            object: nil,
            userInfo: ["duration": targetDuration]
        )
    }
    
    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .idle
        elapsedTime = 0
        remainingTime = 0
        pausedElapsedTime = 0
        startDate = nil
        currentTimerType = nil
        currentTitle = ""
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        // 监听应用进入后台
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.updateLiveActivity()
            }
            .store(in: &cancellables)
        
        // 监听应用回到前台
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.updateLiveActivity()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = FocusTimerAttributes(
            timerType: currentTimerType?.displayName ?? "计时器",
            title: currentTitle,
            colorHex: currentColorHex
        )
        
        let initialState = FocusTimerAttributes.ContentState(
            elapsedTime: elapsedTime,
            remainingTime: remainingTime,
            targetDuration: targetDuration,
            isRunning: timerState == .running,
            isCountdownMode: isCountdownMode
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    private func updateLiveActivity() {
        guard let activity = currentActivity else { return }
        
        let updatedState = FocusTimerAttributes.ContentState(
            elapsedTime: elapsedTime,
            remainingTime: remainingTime,
            targetDuration: targetDuration,
            isRunning: timerState == .running,
            isCountdownMode: isCountdownMode
        )
        
        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }
    
    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = FocusTimerAttributes.ContentState(
            elapsedTime: elapsedTime,
            remainingTime: 0,
            targetDuration: targetDuration,
            isRunning: false,
            isCountdownMode: isCountdownMode
        )
        
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            await MainActor.run {
                currentActivity = nil
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pomodoroCompleted = Notification.Name("pomodoroCompleted")
    static let timerStateChanged = Notification.Name("timerStateChanged")
}
