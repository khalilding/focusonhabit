//
//  AddHabitView.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI
import SwiftData

/// 添加习惯视图
struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedColorHex: String = "#FF6B6B"
    @State private var habitType: HabitType = .positive
    @State private var goalAmount: Double = 1
    @State private var selectedUnit: HabitUnit = .times
    @State private var frequencyType: FrequencyType = .daily
    @State private var selectedDays: Set<Int> = Set(0..<7)
    
    private let icons = [
        "star.fill", "heart.fill", "drop.fill", "flame.fill", "leaf.fill",
        "book.fill", "figure.walk", "dumbbell.fill", "bed.double.fill", "cup.and.saucer.fill",
        "brain.head.profile", "music.note", "paintbrush.fill", "keyboard", "gamecontroller.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 预览卡片
                    previewCard
                    
                    // 基本信息
                    basicInfoSection
                    
                    // 颜色选择
                    colorSelectionSection
                    
                    // 图标选择
                    iconSelectionSection
                    
                    // 目标设置
                    goalSection
                    
                    // 频率设置
                    frequencySection
                }
                .padding(20)
            }
            .background(Color.AppColors.background)
            .navigationTitle("新习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Color.AppColors.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveHabit()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(Color.AppColors.primary)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Preview Card
    
    private var previewCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColorHex).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: selectedIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: selectedColorHex))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title.isEmpty ? "习惯名称" : title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(title.isEmpty ? Color.AppColors.textTertiary : Color.AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Text("0")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundColor(Color(hex: selectedColorHex))
                    
                    Text("/ \(Int(goalAmount)) \(selectedUnit.rawValue)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(Color.AppColors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .tiimoCard()
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本信息")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(Color.AppColors.textSecondary)
            
            TextField("习惯名称", text: $title)
                .font(.system(.body, design: .rounded))
                .padding(16)
                .background(Color.AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // 习惯类型选择
            HStack(spacing: 12) {
                ForEach(HabitType.allCases, id: \.self) { type in
                    Button {
                        habitType = type
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(habitType == type ? .white : Color.AppColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(habitType == type ? Color.AppColors.primary : Color.AppColors.cardBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Color Selection Section
    
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("颜色")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(Color.AppColors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(Color.AppColors.habitColorHexes, id: \.self) { hex in
                    Button {
                        selectedColorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .opacity(selectedColorHex == hex ? 1 : 0)
                            )
                            .shadow(color: selectedColorHex == hex ? Color(hex: hex).opacity(0.5) : .clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Icon Selection Section
    
    private var iconSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("图标")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(Color.AppColors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : Color.AppColors.secondaryBackground)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedIcon == icon ? Color(hex: selectedColorHex) : Color.AppColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Goal Section
    
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目标")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(Color.AppColors.textSecondary)
            
            VStack(spacing: 16) {
                // 数量选择
                HStack {
                    Text("目标数量")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Color.AppColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            if goalAmount > 1 { goalAmount -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color.AppColors.textSecondary)
                        }
                        
                        Text("\(Int(goalAmount))")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(Color(hex: selectedColorHex))
                            .frame(minWidth: 40)
                        
                        Button {
                            goalAmount += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(hex: selectedColorHex))
                        }
                    }
                }
                
                Divider()
                
                // 单位选择
                HStack {
                    Text("单位")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(Color.AppColors.textPrimary)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(HabitUnit.allCases, id: \.self) { unit in
                            Button(unit.rawValue) {
                                selectedUnit = unit
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedUnit.rawValue)
                                .font(.system(.body, design: .rounded, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(Color(hex: selectedColorHex))
                    }
                }
            }
            .padding(16)
            .background(Color.AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Frequency Section
    
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("频率")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(Color.AppColors.textSecondary)
            
            VStack(spacing: 16) {
                // 频率类型
                HStack(spacing: 8) {
                    ForEach(FrequencyType.allCases, id: \.self) { type in
                        Button {
                            frequencyType = type
                        } label: {
                            Text(type.displayName)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundColor(frequencyType == type ? .white : Color.AppColors.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(frequencyType == type ? Color(hex: selectedColorHex) : Color.AppColors.secondaryBackground)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // 具体日期选择
                if frequencyType == .weekly || frequencyType == .daily {
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            Button {
                                if selectedDays.contains(day) {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                            } label: {
                                Text(Date.shortWeekdayNames[day])
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundColor(selectedDays.contains(day) ? .white : Color.AppColors.textSecondary)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(selectedDays.contains(day) ? Color(hex: selectedColorHex) : Color.AppColors.secondaryBackground)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Methods
    
    private func saveHabit() {
        let habit = Habit(
            title: title,
            iconName: selectedIcon,
            colorHex: selectedColorHex,
            type: habitType,
            goalAmount: goalAmount,
            unit: selectedUnit,
            frequencyType: frequencyType,
            specificDays: Array(selectedDays)
        )
        
        modelContext.insert(habit)
        dismiss()
    }
}

// MARK: - Edit Habit View

struct EditHabitView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("编辑习惯功能开发中...")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(Color.AppColors.textSecondary)
                }
                .padding(20)
            }
            .background(Color.AppColors.background)
            .navigationTitle("编辑习惯")
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
}

// MARK: - Preview

#Preview {
    AddHabitView()
        .modelContainer(for: Habit.self, inMemory: true)
}
