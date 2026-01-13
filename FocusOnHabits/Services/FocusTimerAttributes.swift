//
//  FocusTimerAttributes.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import Foundation
import ActivityKit

/// Live Activity 和 Dynamic Island 的属性定义
struct FocusTimerAttributes: ActivityAttributes {
    
    /// 静态属性（创建后不变）
    public let timerType: String
    public let title: String
    public let colorHex: String
    
    /// 动态内容状态
    public struct ContentState: Codable, Hashable {
        /// 已用时间（秒）
        var elapsedTime: TimeInterval
        
        /// 剩余时间（秒）
        var remainingTime: TimeInterval
        
        /// 目标时间（秒）
        var targetDuration: TimeInterval
        
        /// 是否正在运行
        var isRunning: Bool
        
        /// 是否为倒计时模式
        var isCountdownMode: Bool
        
        // MARK: - Computed Properties
        
        /// 进度百分比
        var progress: Double {
            guard targetDuration > 0 else { return 0 }
            return min(elapsedTime / targetDuration, 1.0)
        }
        
        /// 格式化的时间显示
        var formattedTime: String {
            let time = isCountdownMode ? remainingTime : elapsedTime
            return formatTime(time)
        }
        
        /// 格式化的已用时间
        var formattedElapsedTime: String {
            formatTime(elapsedTime)
        }
        
        /// 格式化的剩余时间
        var formattedRemainingTime: String {
            formatTime(remainingTime)
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
    }
}

// MARK: - Live Activity View (Widget Extension)

#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

/// Live Activity 视图扩展
struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(Color(hex: context.attributes.colorHex))
                        Text(context.attributes.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .lineLimit(1)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.formattedTime)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(Color(hex: context.attributes.colorHex))
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: context.attributes.colorHex).opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: context.attributes.colorHex))
                                    .frame(width: geometry.size.width * context.state.progress)
                            }
                        }
                        .frame(height: 8)
                        
                        // 播放/暂停状态
                        Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                            .foregroundColor(Color(hex: context.attributes.colorHex))
                    }
                    .padding(.top, 8)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                // Compact Leading
                Image(systemName: "timer")
                    .foregroundColor(Color(hex: context.attributes.colorHex))
            } compactTrailing: {
                // Compact Trailing
                Text(context.state.formattedTime)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(Color(hex: context.attributes.colorHex))
            } minimal: {
                // Minimal
                Image(systemName: "timer")
                    .foregroundColor(Color(hex: context.attributes.colorHex))
            }
        }
    }
}

/// 锁屏 Live Activity 视图
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<FocusTimerAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color(hex: context.attributes.colorHex).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(Color(hex: context.attributes.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(context.attributes.timerType)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 时间显示
            VStack(alignment: .trailing, spacing: 4) {
                Text(context.state.formattedTime)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(Color(hex: context.attributes.colorHex))
                
                // 状态指示
                HStack(spacing: 4) {
                    Circle()
                        .fill(context.state.isRunning ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    
                    Text(context.state.isRunning ? "运行中" : "已暂停")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
    }
}
#endif
