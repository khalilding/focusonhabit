//
//  Color+Extensions.swift
//  FocusOnHabits
//
//  Created by Focus on Habits Team
//  Version 0.0.1
//

import SwiftUI

extension Color {
    
    /// 从十六进制字符串创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
    
    /// 转换为十六进制字符串
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    /// 调整亮度
    func adjustBrightness(by amount: Double) -> Color {
        let uic = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uic.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(
            hue: Double(hue),
            saturation: Double(saturation),
            brightness: min(max(Double(brightness) + amount, 0), 1),
            opacity: Double(alpha)
        )
    }
}

// MARK: - App Color Palette (Tiimo Style Pastel Colors)

extension Color {
    
    struct AppColors {
        // 主色调
        static let primary = Color(hex: "#6C5CE7")      // 紫色
        static let secondary = Color(hex: "#A29BFE")    // 淡紫色
        
        // 习惯颜色（柔和的粉彩色系）
        static let coral = Color(hex: "#FF6B6B")        // 珊瑚色
        static let peach = Color(hex: "#FFA07A")        // 桃色
        static let mint = Color(hex: "#A8E6CF")         // 薄荷绿
        static let sky = Color(hex: "#74B9FF")          // 天蓝色
        static let lavender = Color(hex: "#DDA0DD")     // 薰衣草紫
        static let sunflower = Color(hex: "#FFD93D")    // 向日葵黄
        static let rose = Color(hex: "#FF8B94")         // 玫瑰粉
        static let sage = Color(hex: "#B5EAD7")         // 鼠尾草绿
        static let periwinkle = Color(hex: "#C4C7FF")   // 长春花蓝
        static let apricot = Color(hex: "#FFDAB9")      // 杏色
        
        // 背景色
        static let background = Color(hex: "#FAFAFA")
        static let cardBackground = Color(hex: "#FFFFFF")
        static let secondaryBackground = Color(hex: "#F5F5F7")
        
        // 文字颜色
        static let textPrimary = Color(hex: "#2D3436")
        static let textSecondary = Color(hex: "#636E72")
        static let textTertiary = Color(hex: "#B2BEC3")
        
        // 状态颜色
        static let success = Color(hex: "#00B894")
        static let warning = Color(hex: "#FDCB6E")
        static let error = Color(hex: "#E17055")
        
        /// 预设习惯颜色数组
        static let habitColors: [Color] = [
            coral, peach, mint, sky, lavender,
            sunflower, rose, sage, periwinkle, apricot
        ]
        
        /// 预设习惯颜色十六进制数组
        static let habitColorHexes: [String] = [
            "#FF6B6B", "#FFA07A", "#A8E6CF", "#74B9FF", "#DDA0DD",
            "#FFD93D", "#FF8B94", "#B5EAD7", "#C4C7FF", "#FFDAB9"
        ]
    }
}
