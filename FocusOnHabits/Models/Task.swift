//
//  Task.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import Foundation
import SwiftData

/// 任务优先级
enum TaskPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .urgent: return "紧急"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "flag"
        case .medium: return "flag.fill"
        case .high: return "exclamationmark.triangle"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    var colorHex: String {
        switch self {
        case .low: return "#A8E6CF"
        case .medium: return "#FFD93D"
        case .high: return "#FF8B94"
        case .urgent: return "#FF6B6B"
        }
    }
}

/// 任务数据模型 - CloudKit 兼容
@Model
final class Task {
    /// 唯一标识符
    var id: UUID
    
    /// 任务标题
    var title: String
    
    /// 任务描述
    var taskDescription: String?
    
    /// 是否已完成
    var isCompleted: Bool
    
    /// 完成时间
    var completedAt: Date?
    
    /// 截止日期
    var dueDate: Date?
    
    /// 优先级
    var priorityRawValue: Int
    
    /// 花费时间（秒）
    var timeSpent: TimeInterval
    
    /// 颜色十六进制值
    var colorHex: String
    
    /// 排序顺序
    var sortOrder: Int
    
    /// 是否归档
    var isArchived: Bool
    
    /// 归档的子任务状态（JSON 字符串）
    var archivedSubTaskStates: String?
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 父任务
    var parentTask: Task?
    
    /// 子任务
    @Relationship(deleteRule: .cascade, inverse: \Task.parentTask)
    var subTasks: [Task]
    
    // MARK: - Computed Properties
    
    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }
    
    var isSubTask: Bool {
        parentTask != nil
    }
    
    var hasSubTasks: Bool {
        !subTasks.isEmpty
    }
    
    /// 计算子任务完成进度
    var subTaskProgress: Double {
        guard hasSubTasks else { return isCompleted ? 1.0 : 0.0 }
        let completed = subTasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(subTasks.count)
    }
    
    /// 格式化的时间显示
    var formattedTimeSpent: String {
        let hours = Int(timeSpent) / 3600
        let minutes = Int(timeSpent) / 60 % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "0分钟"
        }
    }
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String? = nil,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        colorHex: String = "#6C5CE7",
        sortOrder: Int = 0,
        parentTask: Task? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priorityRawValue = priority.rawValue
        self.timeSpent = 0
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.parentTask = parentTask
        self.subTasks = []
    }
    
    // MARK: - Methods
    
    /// 标记任务为完成
    func markAsCompleted() {
        // 保存子任务状态
        if hasSubTasks {
            archiveSubTaskStates()
        }
        
        // 标记所有子任务为完成
        for subTask in subTasks {
            subTask.isCompleted = true
            subTask.completedAt = Date()
            subTask.updatedAt = Date()
        }
        
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
    }
    
    /// 取消完成状态
    func markAsIncomplete() {
        // 恢复子任务状态
        if hasSubTasks {
            restoreSubTaskStates()
        }
        
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }
    
    /// 归档子任务状态
    private func archiveSubTaskStates() {
        let states = subTasks.map { SubTaskState(id: $0.id, isCompleted: $0.isCompleted) }
        if let data = try? JSONEncoder().encode(states),
           let jsonString = String(data: data, encoding: .utf8) {
            archivedSubTaskStates = jsonString
        }
    }
    
    /// 恢复子任务状态
    private func restoreSubTaskStates() {
        guard let jsonString = archivedSubTaskStates,
              let data = jsonString.data(using: .utf8),
              let states = try? JSONDecoder().decode([SubTaskState].self, from: data) else {
            return
        }
        
        for subTask in subTasks {
            if let state = states.first(where: { $0.id == subTask.id }) {
                subTask.isCompleted = state.isCompleted
                subTask.completedAt = state.isCompleted ? Date() : nil
                subTask.updatedAt = Date()
            }
        }
        
        archivedSubTaskStates = nil
    }
    
    /// 增加计时
    func addTimeSpent(_ seconds: TimeInterval) {
        timeSpent += seconds
        updatedAt = Date()
    }
}

/// 子任务状态存储结构
struct SubTaskState: Codable {
    let id: UUID
    let isCompleted: Bool
}

// MARK: - AI Subtask Generator (Placeholder)

/// AI 子任务生成器（占位符，为后续 LLM 集成准备）
func generateSubtasks(for task: Task) -> [String] {
    // TODO: 将来集成 LLM API
    // 目前返回模拟数据
    
    let mockSubtasks: [String] = [
        "第一步：分析任务需求",
        "第二步：收集相关资料",
        "第三步：制定执行计划",
        "第四步：执行主要工作",
        "第五步：检查和验证结果",
        "第六步：总结和归档"
    ]
    
    return mockSubtasks
}
