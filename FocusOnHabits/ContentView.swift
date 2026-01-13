//
//  ContentView.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI

/// 主选项卡枚举
enum MainTab: Int, CaseIterable {
    case habits = 0
    case tasks = 1
    case report = 2
    case pomodoro = 3
    
    var title: String {
        switch self {
        case .habits: return "习惯"
        case .tasks: return "任务"
        case .report: return "报告"
        case .pomodoro: return "专注"
        }
    }
    
    var icon: String {
        switch self {
        case .habits: return "leaf.fill"
        case .tasks: return "checklist"
        case .report: return "chart.bar.fill"
        case .pomodoro: return "timer"
        }
    }
    
    var selectedIcon: String {
        icon
    }
}

/// 主视图
struct ContentView: View {
    @State private var selectedTab: MainTab = .habits
    @EnvironmentObject var timerService: TimerService
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            TabView(selection: $selectedTab) {
                HabitsView()
                    .tag(MainTab.habits)
                
                TasksView()
                    .tag(MainTab.tasks)
                
                ReportView()
                    .tag(MainTab.report)
                
                PomodoroView()
                    .tag(MainTab.pomodoro)
            }
            
            // 自定义 Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
    }
}

/// 自定义 Tab Bar（Tiimo 风格）
struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    animation: animation
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    // 触觉反馈
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
}

/// Tab Bar 按钮
struct TabBarButton: View {
    let tab: MainTab
    let isSelected: Bool
    var animation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.AppColors.primary.opacity(0.15))
                        .frame(width: 48, height: 48)
                        .matchedGeometryEffect(id: "TAB_BG", in: animation)
                }
                
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? Color.AppColors.primary : Color.AppColors.textTertiary)
            }
            .frame(width: 48, height: 48)
            
            Text(tab.title)
                .font(.system(size: 10, design: .rounded, weight: .medium))
                .foregroundColor(isSelected ? Color.AppColors.primary : Color.AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(TimerService.shared)
}
