//
//  HabitLog.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import Foundation
import SwiftData

/// 习惯记录数据模型 - CloudKit 兼容
@Model
final class HabitLog {
    /// 唯一标识符
    var id: UUID
    
    /// 记录日期（仅日期部分，忽略时间）
    var date: Date
    
    /// 记录的数值（用于计数类习惯）
    var valueLogged: Double
    
    /// 记录的时长（秒，用于计时类习惯）
    var durationLogged: TimeInterval
    
    /// 备注
    var note: String?
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 关联的习惯
    var habit: Habit?
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        valueLogged: Double = 0,
        durationLogged: TimeInterval = 0,
        note: String? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.valueLogged = valueLogged
        self.durationLogged = durationLogged
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Helper Methods
    
    /// 增加数值
    func incrementValue(by amount: Double = 1) {
        valueLogged += amount
        updatedAt = Date()
    }
    
    /// 增加时长（秒）
    func incrementDuration(by seconds: TimeInterval) {
        durationLogged += seconds
        updatedAt = Date()
    }
    
    /// 格式化的时长显示
    var formattedDuration: String {
        let hours = Int(durationLogged) / 3600
        let minutes = Int(durationLogged) / 60 % 60
        let seconds = Int(durationLogged) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
