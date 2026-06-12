import SwiftUI

/// 速度圆盘：外圈刻度 + 中间速度数字 + 海拔 + 指南针（Liquid glass 风格）
struct SpeedometerDial: View {
    var speed: Double             // km/h
    var altitude: Double          // meters
    var heading: Double           // degrees

    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height)
            ZStack {
                // 外圈玻璃背景
                Circle()
                    .fill(.ultraThinMaterial)
                Circle()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)

                // 外环轨道
                Circle()
                    .trim(from: 0.2, to: 0.8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .rotationEffect(.degrees(90))
                    .padding(diameter * 0.05)

                // 实时圆弧（0-200 km/h -> 0~1
                let progress = min(max(speed / 200.0, 0.0), 1.0)
                Circle()
                    .trim(from: 0.2, to: 0.2 + progress * 0.6)
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .blue, .purple, .pink, .orange, .red],
                            center: .center,
                            startAngle: .degrees(72 + 90),
                            endAngle: .degrees(288 + 90)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(180))
                    .padding(diameter * 0.06)

                // 刻度
                TickMarks(diameter: diameter)

                // 中间内容
                VStack(spacing: 2) {
                    Text("\(Int(speed.rounded()))")
                        .font(.system(size: diameter * 0.34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    Text("km/h")
                        .font(.system(size: diameter * 0.08, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))

                    HStack(spacing: 12) {
                        // 海拔
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "mountain.2.fill")
                                    .foregroundStyle(.white)
                                Text("海拔")
                                    .font(.system(size: diameter * 0.055, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            Text("\(Int(altitude.rounded())) m")
                                .font(.system(size: diameter * 0.075, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .liquidGlass(radius: 14, fill: .thinMaterial)

                        // 指南针
                        CompassView(heading: heading)
                            .frame(width: diameter * 0.24, height: diameter * 0.24)
                            .liquidGlass(radius: (diameter * 0.24) / 2, fill: .thinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.top, diameter * 0.04)
                }
            }
            .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 8)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// 刻度线（0 ~ 200 km/h
private struct TickMarks: View {
    var diameter: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<21, id: \.self) { i in
                let ratio = Double(i) / 20.0
                let angle = -108.0 + ratio * 216.0   // 从 -108 度 至 108 度（216 度弧线
                let isMajor = i % 5 == 0
                Rectangle()
                    .fill(Color.white.opacity(isMajor ? 0.85 : 0.35))
                    .frame(width: isMajor ? 2 : 1, height: isMajor ? diameter * 0.04 : diameter * 0.02)
                    .offset(y: -diameter * 0.42)
                    .rotationEffect(.degrees(angle))
                if isMajor {
                    Text("\(i * 10)")
                        .font(.system(size: diameter * 0.05, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .offset(y: -diameter * 0.34)
                        .rotationEffect(.degrees(angle))
                        .rotationEffect(.degrees(-angle))
                }
            }
        }
    }
}

/// 小型指南针（N/E/S/W 四字 + 指针）
struct CompassView: View {
    var heading: Double
    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(Color.white.opacity(0.12))
                // N/E/S/W
                Text("N")
                    .font(.system(size: d * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.red)
                    .offset(y: -d * 0.34)
                Text("E")
                    .font(.system(size: d * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .offset(x: d * 0.34)
                Text("S")
                    .font(.system(size: d * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .offset(y: d * 0.34)
                Text("W")
                    .font(.system(size: d * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .offset(x: -d * 0.34)

                // 指针
                VStack(spacing: 0) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: d * 0.28))
                }
                .offset(y: -d * 0.08)
            }
            .rotationEffect(.degrees(-heading))
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple, .indigo], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        SpeedometerDial(speed: 85.4, altitude: 123, heading: 45)
            .padding()
    }
}
