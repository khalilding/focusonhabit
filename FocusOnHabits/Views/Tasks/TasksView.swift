//
//  TasksView.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI
import SwiftData

/// 任务主视图
struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Task> { $0.parentTask == nil && !$0.isArchived },
        sort: \Task.sortOrder
    ) private var tasks: [Task]
    
    @State private var showingAddTask = false
    @State private var expandedTaskIds: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppColors.background
                    .ignoresSafeArea()
                
                if tasks.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            // 未完成的任务
                            ForEach(tasks.filter { !$0.isCompleted }) { task in
                                TaskCardView(
                                    task: task,
                                    isExpanded: expandedTaskIds.contains(task.id)
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        if expandedTaskIds.contains(task.id) {
                                            expandedTaskIds.remove(task.id)
                                        } else {
                                            expandedTaskIds.insert(task.id)
                                        }
                                    }
                                }
                            }
                            
                            // 已完成的任务
                            if !tasks.filter({ $0.isCompleted }).isEmpty {
                                HStack {
                                    Text("已完成")
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundColor(Color.AppColors.textSecondary)
                                    Spacer()
                                }
                                .padding(.top, 8)
                                
                                ForEach(tasks.filter { $0.isCompleted }) { task in
                                    TaskCardView(
                                        task: task,
                                        isExpanded: expandedTaskIds.contains(task.id)
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            if expandedTaskIds.contains(task.id) {
                                                expandedTaskIds.remove(task.id)
                                            } else {
                                                expandedTaskIds.insert(task.id)
                                            }
                                        }
                                    }
                                    .opacity(0.6)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationTitle("任务")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(Color.AppColors.textTertiary)
            
            Text("暂无任务")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(Color.AppColors.textSecondary)
            
            Text("点击右上角添加你的第一个任务")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color.AppColors.textTertiary)
        }
    }
}

// MARK: - Task Card View

struct TaskCardView: View {
    @Bindable var task: Task
    var isExpanded: Bool
    var onTap: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var timerService: TimerService
    
    private var taskColor: Color { Color(hex: task.colorHex) }
    
    var body: some View {
        VStack(spacing: 0) {
            // 主任务
            HStack(spacing: 16) {
                // 完成按钮
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if task.isCompleted {
                            task.markAsIncomplete()
                        } else {
                            task.markAsCompleted()
                        }
                    }
                    // 触觉反馈
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(taskColor, lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if task.isCompleted {
                            Circle()
                                .fill(taskColor)
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // 任务信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(Color.AppColors.textPrimary)
                        .strikethrough(task.isCompleted, color: Color.AppColors.textSecondary)
                    
                    if task.hasSubTasks {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.caption2)
                            Text("\(task.subTasks.filter { $0.isCompleted }.count)/\(task.subTasks.count)")
                                .font(.system(.caption, design: .rounded))
                        }
                        .foregroundColor(Color.AppColors.textSecondary)
                    }
                    
                    if task.timeSpent > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(task.formattedTimeSpent)
                                .font(.system(.caption, design: .rounded))
                        }
                        .foregroundColor(Color.AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // 计时按钮
                TimerTaskButton(task: task)
                
                // 展开按钮
                if task.hasSubTasks {
                    Button(action: onTap) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.AppColors.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            
            // 子任务列表
            if isExpanded && task.hasSubTasks {
                VStack(spacing: 8) {
                    ForEach(task.subTasks.sorted(by: { $0.sortOrder < $1.sortOrder })) { subTask in
                        SubTaskRow(subTask: subTask, parentColor: taskColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.leading, 44) // 与主任务对齐
            }
        }
        .tiimoCard()
        .onTapGesture {
            if task.hasSubTasks {
                onTap()
            }
        }
    }
}

// MARK: - Timer Task Button

struct TimerTaskButton: View {
    let task: Task
    @EnvironmentObject var timerService: TimerService
    
    private var isRunning: Bool {
        if case .task(let id) = timerService.currentTimerType {
            return id == task.id && timerService.timerState == .running
        }
        return false
    }
    
    var body: some View {
        Button {
            if isRunning {
                let elapsed = timerService.stopTimer()
                task.addTimeSpent(elapsed)
            } else {
                timerService.startTaskTimer(
                    taskId: task.id,
                    title: task.title,
                    colorHex: task.colorHex
                )
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: task.colorHex).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: task.colorHex))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sub Task Row

struct SubTaskRow: View {
    @Bindable var subTask: Task
    let parentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    subTask.isCompleted.toggle()
                    subTask.completedAt = subTask.isCompleted ? Date() : nil
                    subTask.updatedAt = Date()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(parentColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    
                    if subTask.isCompleted {
                        Circle()
                            .fill(parentColor.opacity(0.5))
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Text(subTask.title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color.AppColors.textPrimary)
                .strikethrough(subTask.isCompleted, color: Color.AppColors.textSecondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Task View

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var selectedColorHex: String = "#6C5CE7"
    @State private var priority: TaskPriority = .medium
    @State private var subTasks: [String] = []
    @State private var newSubTaskText: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题输入
                    VStack(alignment: .leading, spacing: 12) {
                        Text("任务标题")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(Color.AppColors.textSecondary)
                        
                        TextField("输入任务标题", text: $title)
                            .font(.system(.body, design: .rounded))
                            .padding(16)
                            .background(Color.AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    // 颜色选择
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
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .background(Color.AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    // 优先级选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("优先级")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(Color.AppColors.textSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Button {
                                    priority = p
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: p.icon)
                                            .font(.system(size: 16))
                                        Text(p.displayName)
                                            .font(.system(.caption, design: .rounded))
                                    }
                                    .foregroundColor(priority == p ? .white : Color.AppColors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(priority == p ? Color(hex: p.colorHex) : Color.AppColors.cardBackground)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 子任务
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("子任务")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(Color.AppColors.textSecondary)
                            
                            Spacer()
                            
                            Button {
                                // AI 生成子任务（占位）
                                let mockSubtasks = generateSubtasks(for: Task(title: title))
                                subTasks.append(contentsOf: mockSubtasks)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("AI 生成")
                                }
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(Color.AppColors.primary)
                            }
                            .disabled(title.isEmpty)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(subTasks.indices, id: \.self) { index in
                                HStack {
                                    Circle()
                                        .stroke(Color(hex: selectedColorHex), lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                    
                                    Text(subTasks[index])
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(Color.AppColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        subTasks.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color.AppColors.textTertiary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            // 添加子任务输入
                            HStack {
                                TextField("添加子任务", text: $newSubTaskText)
                                    .font(.system(.subheadline, design: .rounded))
                                
                                Button {
                                    if !newSubTaskText.isEmpty {
                                        subTasks.append(newSubTaskText)
                                        newSubTaskText = ""
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color(hex: selectedColorHex))
                                }
                                .disabled(newSubTaskText.isEmpty)
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(16)
                        .background(Color.AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(Color.AppColors.background)
            .navigationTitle("新任务")
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
                        saveTask()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(Color.AppColors.primary)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let task = Task(
            title: title,
            priority: priority,
            colorHex: selectedColorHex
        )
        
        // 添加子任务
        for (index, subTaskTitle) in subTasks.enumerated() {
            let subTask = Task(
                title: subTaskTitle,
                colorHex: selectedColorHex,
                sortOrder: index,
                parentTask: task
            )
            modelContext.insert(subTask)
        }
        
        modelContext.insert(task)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    TasksView()
        .modelContainer(for: [Task.self], inMemory: true)
        .environmentObject(TimerService.shared)
}
