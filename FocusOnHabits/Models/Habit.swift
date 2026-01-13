//
//  Habit.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import Foundation
import SwiftData

/// 习惯类型枚举
enum HabitType: String, Codable, CaseIterable {
    case positive = "positive"  // 积极习惯（要培养的）
    case negative = "negative"  // 消极习惯（要戒除的）
    
    var displayName: String {
        switch self {
        case .positive: return "培养习惯"
        case .negative: return "戒除习惯"
        }
    }
    
    var icon: String {
        switch self {
        case .positive: return "plus.circle.fill"
        case .negative: return "minus.circle.fill"
        }
    }
}

/// 频率类型枚举
enum FrequencyType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        }
    }
}

/// 习惯单位枚举
enum HabitUnit: String, Codable, CaseIterable {
    case times = "次"
    case minutes = "分钟"
    case hours = "小时"
    case glasses = "杯"
    case pages = "页"
    case steps = "步"
    case kilometers = "公里"
    case calories = "卡路里"
    case custom = "自定义"
    
    var isTimeBased: Bool {
        self == .minutes || self == .hours
    }
}

/// 习惯数据模型 - CloudKit 兼容
@Model
final class Habit {
    /// 唯一标识符
    var id: UUID
    
    /// 习惯标题
    var title: String
    
    /// 习惯图标 (SF Symbol 名称)
    var iconName: String
    
    /// 颜色十六进制值
    var colorHex: String
    
    /// 习惯类型（积极/消极）
    var typeRawValue: String
    
    /// 目标数量
    var goalAmount: Double
    
    /// 单位
    var unitRawValue: String
    
    /// 频率类型
    var frequencyTypeRawValue: String
    
    /// 特定日期（0=周日, 1=周一, ..., 6=周六）
    var specificDays: [Int]
    
    /// 排序顺序
    var sortOrder: Int
    
    /// 是否归档
    var isArchived: Bool
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 关联的习惯记录
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]
    
    // MARK: - Computed Properties
    
    var type: HabitType {
        get { HabitType(rawValue: typeRawValue) ?? .positive }
        set { typeRawValue = newValue.rawValue }
    }
    
    var unit: HabitUnit {
        get { HabitUnit(rawValue: unitRawValue) ?? .times }
        set { unitRawValue = newValue.rawValue }
    }
    
    var frequencyType: FrequencyType {
        get { FrequencyType(rawValue: frequencyTypeRawValue) ?? .daily }
        set { frequencyTypeRawValue = newValue.rawValue }
    }
    
    var isTimeBased: Bool {
        unit.isTimeBased
    }
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        title: String,
        iconName: String = "star.fill",
        colorHex: String = "#FF6B6B",
        type: HabitType = .positive,
        goalAmount: Double = 1,
        unit: HabitUnit = .times,
        frequencyType: FrequencyType = .daily,
        specificDays: [Int] = [0, 1, 2, 3, 4, 5, 6],
        sortOrder: Int = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.colorHex = colorHex
        self.typeRawValue = type.rawValue
        self.goalAmount = goalAmount
        self.unitRawValue = unit.rawValue
        self.frequencyTypeRawValue = frequencyType.rawValue
        self.specificDays = specificDays
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = Date()
        self.updatedAt = Date()
        self.logs = []
    }
    
    // MARK: - Helper Methods
    
    /// 获取指定日期的记录
    func log(for date: Date) -> HabitLog? {
        let calendar = Calendar.current
        return logs.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    /// 获取今日记录
    func todayLog() -> HabitLog? {
        log(for: Date())
    }
    
    /// 计算指定日期的完成率
    func completionRate(for date: Date) -> Double {
        guard let log = log(for: date) else { return 0 }
        
        if isTimeBased {
            return min(log.durationLogged / (goalAmount * 60), 1.0) // 转换为秒
        } else {
            return min(log.valueLogged / goalAmount, 1.0)
        }
    }
    
    /// 检查今天是否应该执行该习惯
    func isScheduledForToday() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) - 1 // 0=周日
        return specificDays.contains(weekday)
    }
    
    /// 检查今天是否已完成
    func isCompletedToday() -> Bool {
        completionRate(for: Date()) >= 1.0
    }
}
