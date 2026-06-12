import SwiftUI

/// Liquid Glass (液态玻璃) 风格视觉修饰符：
/// 使用 iOS 15+ 原生 .ultraThinMaterial / .ultraThinMaterial / .regularMaterial 等模糊材质，
/// 叠加描边、高光、柔和阴影，模拟 Apple visionOS / iOS Control Center 的 Glass 风格
struct LiquidGlassStyle: ViewModifier {
    var radius: CGFloat = 24
    var fill: Material = .ultraThinMaterial
    var stroke: Color = .white.opacity(0.25)
    var shadowRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(fill)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(stroke, lineWidth: 0.8)
                    // 顶部高光
                    LinearGradient(
                        colors: [.white.opacity(0.18), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                }
            )
            .shadow(color: .black.opacity(0.35), radius: shadowRadius, x: 0, y: shadowRadius / 3)
    }
}

/// 圆形玻璃卡片
struct LiquidGlassCircle: ViewModifier {
    var diameter: CGFloat
    var fill: Material = .ultraThinMaterial

    func body(content: Content) -> some View {
        content
            .frame(width: diameter, height: diameter)
            .background(
                ZStack {
                    Circle().fill(fill)
                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                    Circle()
                        .trim(from: 0.5, to: 1.0)
                        .stroke(
                            LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0)],
                                           startPoint: .top, endPoint: .bottom),
                            lineWidth: 0.8
                        )
                        .rotationEffect(.degrees(-45))
                }
            )
            .shadow(color: .black.opacity(0.4), radius: 18, x: 0, y: 8)
    }
}

extension View {
    func liquidGlass(radius: CGFloat = 24, fill: Material = .ultraThinMaterial) -> some View {
        modifier(LiquidGlassStyle(radius: radius, fill: fill))
    }

    func liquidGlassCircle(diameter: CGFloat, fill: Material = .ultraThinMaterial) -> some View {
        modifier(LiquidGlassCircle(diameter: diameter, fill: fill))
    }
}

/// 通用的大标题数字字体风格
struct BigDigitStyle: ViewModifier {
    var size: CGFloat
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}
extension View {
    func bigDigit(_ size: CGFloat = 80) -> some View { modifier(BigDigitStyle(size: size)) }
}
