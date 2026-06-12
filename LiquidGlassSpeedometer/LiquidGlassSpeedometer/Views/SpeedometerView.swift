import SwiftUI

/// 根 TabView：地图 / 码表 / 历史 / 设置
struct RootTabView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        TabView {
            NavigationStack { MapTrackView() }
                .tabItem { Label("地图", systemImage: "map.fill") }

            NavigationStack { SpeedometerView() }
                .tabItem { Label("码表", systemImage: "gauge.with.dots.needle.bottom.50percent") }

            NavigationStack { HistoryListView() }
                .tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }

            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
        }
        .tint(.cyan)
        .preferredColorScheme(.dark)
    }
}

/// 码表主界面：圆盘 + 统计信息 + 开始/停止
struct SpeedometerView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            // 背景：深色渐变（模拟 Apple 液态玻璃背景
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.35),
                         Color(red: 0.42, green: 0.22, blue: 0.55),
                         Color(red: 0.12, green: 0.14, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                // 圆盘
                SpeedometerDial(
                    speed: app.currentSpeed,
                    altitude: app.altitude,
                    heading: app.heading
                )
                .padding(.horizontal, 24)

                // 时长 + 平均时速
                HStack(spacing: 12) {
                    InfoCard(title: "时长", value: AppState.formatDuration(app.elapsed), systemImage: "stopwatch.fill")
                    InfoCard(title: "平均", value: String(format: "%.1f km/h", app.averageSpeed), systemImage: "speedometer")
                }
                .padding(.horizontal, 20)

                // 开始时间 + 最高速度
                HStack(spacing: 12) {
                    InfoCard(title: "开始时间",
                             value: app.startTime != nil ? Self.timestampFormatter.string(from: app.startTime!) : "--:--",
                             systemImage: "calendar.badge.clock")
                    InfoCard(title: "最高时速",
                             value: String(format: "%.1f km/h", app.maxSpeed),
                             systemImage: "flame.fill")
                }
                .padding(.horizontal, 20)

                // 开始/结束按钮
                Button {
                    if app.isRecording { app.stopRecording() } else { app.startRecording() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: app.isRecording ? "stop.fill" : "play.fill")
                        Text(app.isRecording ? "停止并保存" : "开始记录")
                    }
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(app.isRecording ? AnyShapeStyle(Color.red.opacity(0.9)) : AnyShapeStyle(Color.green.opacity(0.9)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.top, 12)
        }
        .navigationTitle("码表")
        .navigationBarTitleDisplayMode(.inline)
    }

    static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()
}

/// 小型信息卡
private struct InfoCard: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(12)
        .liquidGlass(radius: 18, fill: .ultraThinMaterial)
    }
}
