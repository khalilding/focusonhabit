//
//  FocusOnHabitsWidgets.swift
//  FocusOnHabitsWidgets
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Live Activity Widget Bundle

@main
struct FocusOnHabitsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FocusTimerLiveActivity()
    }
}

// MARK: - Focus Timer Live Activity

struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
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
                    HStack(spacing: 12) {
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
                        
                        // 状态指示
                        Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: context.attributes.colorHex))
                    }
                    .padding(.top, 8)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(Color(hex: context.attributes.colorHex))
            } compactTrailing: {
                Text(context.state.formattedTime)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(Color(hex: context.attributes.colorHex))
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(Color(hex: context.attributes.colorHex))
            }
        }
    }
}

// MARK: - Lock Screen Live Activity View

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

// MARK: - Color Extension (for Widget)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Focus Timer Attributes (Shared)

struct FocusTimerAttributes: ActivityAttributes {
    public let timerType: String
    public let title: String
    public let colorHex: String
    
    public struct ContentState: Codable, Hashable {
        var elapsedTime: TimeInterval
        var remainingTime: TimeInterval
        var targetDuration: TimeInterval
        var isRunning: Bool
        var isCountdownMode: Bool
        
        var progress: Double {
            guard targetDuration > 0 else { return 0 }
            return min(elapsedTime / targetDuration, 1.0)
        }
        
        var formattedTime: String {
            let time = isCountdownMode ? remainingTime : elapsedTime
            return formatTime(time)
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
