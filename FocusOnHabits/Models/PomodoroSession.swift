//
//  PomodoroSession.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import Foundation
import SwiftData

/// 番茄钟状态
enum PomodoroStatus: String, Codable, CaseIterable {
    case running = "running"
    case paused = "paused"
    case completed = "completed"
    case interrupted = "interrupted"
    
    var displayName: String {
        switch self {
        case .running: return "进行中"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .interrupted: return "已中断"
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "play.circle.fill"
        case .paused: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .interrupted: return "xmark.circle.fill"
        }
    }
}

/// 番茄钟会话数据模型 - CloudKit 兼容
@Model
final class PomodoroSession {
    /// 唯一标识符
    var id: UUID
    
    /// 开始时间
    var startTime: Date
    
    /// 结束时间
    var endTime: Date?
    
    /// 计划时长（秒）
    var plannedDuration: TimeInterval
    
    /// 实际时长（秒）
    var actualDuration: TimeInterval
    
    /// 状态
    var statusRawValue: String
    
    /// 标签/标题
    var label: String?
    
    /// 备注
    var note: String?
    
    /// 创建时间
    var createdAt: Date
    
    // MARK: - Computed Properties
    
    var status: PomodoroStatus {
        get { PomodoroStatus(rawValue: statusRawValue) ?? .completed }
        set { statusRawValue = newValue.rawValue }
    }
    
    /// 格式化的计划时长
    var formattedPlannedDuration: String {
        formatDuration(plannedDuration)
    }
    
    /// 格式化的实际时长
    var formattedActualDuration: String {
        formatDuration(actualDuration)
    }
    
    /// 完成百分比
    var completionPercentage: Double {
        guard plannedDuration > 0 else { return 0 }
        return min(actualDuration / plannedDuration, 1.0)
    }
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        plannedDuration: TimeInterval = 30 * 60, // 默认30分钟
        label: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.plannedDuration = plannedDuration
        self.actualDuration = 0
        self.statusRawValue = PomodoroStatus.running.rawValue
        self.label = label
        self.createdAt = Date()
    }
    
    // MARK: - Methods
    
    /// 完成会话
    func complete() {
        endTime = Date()
        actualDuration = endTime!.timeIntervalSince(startTime)
        status = .completed
    }
    
    /// 中断会话
    func interrupt() {
        endTime = Date()
        actualDuration = endTime!.timeIntervalSince(startTime)
        status = .interrupted
    }
    
    /// 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
