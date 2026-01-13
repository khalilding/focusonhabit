//
//  Date+Extensions.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import Foundation

extension Date {
    
    // MARK: - Calendar Helpers
    
    /// 获取周日为第一天的日历
    static var sundayFirstCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 1 = 周日
        return calendar
    }
    
    /// 获取当天开始时间
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 获取当天结束时间
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// 获取本周开始日期（周日）
    var startOfWeek: Date {
        let calendar = Date.sundayFirstCalendar
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 获取本周结束日期（周六）
    var endOfWeek: Date {
        let calendar = Date.sundayFirstCalendar
        var components = DateComponents()
        components.day = 6
        return calendar.date(byAdding: components, to: startOfWeek) ?? self
    }
    
    /// 获取本月开始日期
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 获取本月结束日期
    var endOfMonth: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return calendar.date(byAdding: components, to: startOfMonth) ?? self
    }
    
    /// 获取本年开始日期
    var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 获取本年结束日期
    var endOfYear: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 1
        components.day = -1
        return calendar.date(byAdding: components, to: startOfYear) ?? self
    }
    
    // MARK: - Date Components
    
    /// 获取星期几（0=周日, 1=周一, ..., 6=周六）
    var weekdayIndex: Int {
        let calendar = Date.sundayFirstCalendar
        return calendar.component(.weekday, from: self) - 1
    }
    
    /// 获取星期几名称
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// 获取星期几短名称
    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    /// 获取日期数字
    var dayNumber: Int {
        Calendar.current.component(.day, from: self)
    }
    
    /// 获取月份
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    /// 获取年份
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    // MARK: - Date Navigation
    
    /// 添加天数
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// 添加周数
    func addingWeeks(_ weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }
    
    /// 添加月数
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    // MARK: - Date Comparison
    
    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 是否是明天
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// 是否在同一天
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    /// 是否在同一周
    func isSameWeek(as date: Date) -> Bool {
        let calendar = Date.sundayFirstCalendar
        return calendar.isDate(self, equalTo: date, toGranularity: .weekOfYear)
    }
    
    /// 是否在同一月
    func isSameMonth(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }
    
    // MARK: - Date Range
    
    /// 获取一周的日期数组（从周日开始）
    func weekDates() -> [Date] {
        let start = startOfWeek
        return (0..<7).map { start.addingDays($0) }
    }
    
    /// 获取一个月的日期数组
    func monthDates() -> [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: self)!
        let start = startOfMonth
        return range.map { start.addingDays($0 - 1) }
    }
    
    /// 获取一年的日期数组
    func yearDates() -> [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .year, for: self)!
        let start = startOfYear
        return range.map { start.addingDays($0 - 1) }
    }
    
    // MARK: - Formatting
    
    /// 格式化为 "MM月dd日"
    var monthDayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: self)
    }
    
    /// 格式化为 "yyyy年MM月"
    var yearMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: self)
    }
    
    /// 格式化为 "dd"
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: self)
    }
    
    /// 相对时间描述
    var relativeDescription: String {
        if isToday {
            return "今天"
        } else if isYesterday {
            return "昨天"
        } else if isTomorrow {
            return "明天"
        } else {
            return monthDayString
        }
    }
}

// MARK: - Weekday Names

extension Date {
    /// 星期名称数组（周日开始）
    static let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
    
    /// 星期短名称数组
    static let shortWeekdayNames = ["日", "一", "二", "三", "四", "五", "六"]
}
