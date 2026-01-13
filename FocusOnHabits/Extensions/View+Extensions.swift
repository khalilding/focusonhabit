//
//  View+Extensions.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI

// MARK: - Tiimo Style Modifiers

extension View {
    
    /// Tiimo 风格卡片样式
    func tiimoCard(
        cornerRadius: CGFloat = 24,
        shadowRadius: CGFloat = 8,
        shadowOpacity: Double = 0.08
    ) -> some View {
        self
            .background(Color.AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }
    
    /// Tiimo 风格圆形按钮
    func tiimoCircleButton(
        size: CGFloat = 44,
        backgroundColor: Color = Color.AppColors.primary
    ) -> some View {
        self
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
    }
    
    /// Tiimo 风格胶囊按钮
    func tiimoCapsuleButton(
        backgroundColor: Color = Color.AppColors.primary,
        horizontalPadding: CGFloat = 20,
        verticalPadding: CGFloat = 12
    ) -> some View {
        self
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
    
    /// 圆角系统字体
    func roundedFont(
        _ style: Font.TextStyle = .body,
        weight: Font.Weight = .regular
    ) -> some View {
        self.font(.system(style, design: .rounded, weight: weight))
    }
    
    /// 渐变遮罩
    func gradientMask(_ colors: [Color]) -> some View {
        self.mask(
            LinearGradient(
                colors: colors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Conditional Modifier

extension View {
    /// 条件性应用修饰器
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 条件性应用修饰器（带 else）
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Haptic Feedback

extension View {
    /// 添加触觉反馈
    func hapticFeedback(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    ) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
}

// MARK: - Animation

extension View {
    /// 弹簧动画
    func springAnimation(
        response: Double = 0.5,
        dampingFraction: Double = 0.7
    ) -> some View {
        self.animation(
            .spring(response: response, dampingFraction: dampingFraction),
            value: UUID()
        )
    }
}

// MARK: - Placeholder

extension View {
    /// 骨架屏占位符
    func placeholder(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> some View
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self.opacity(shouldShow ? 0 : 1)
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.5),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// 闪光加载效果
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Corner Radius

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    /// 特定角的圆角
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
