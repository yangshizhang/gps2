import SwiftUI
import MapKit

/// 历史记录详情：数据汇总 + 缩略地图 + 车速图表
struct HistoryDetailView: View {
    @ObservedObject var session: Session
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.35),
                         Color(red: 0.12, green: 0.14, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    // 顶部信息卡：开始时间 + 时长 + 距离
                    VStack(spacing: 10) {
                        HStack {
                            Text(session.title ?? "")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            SmallMetric(title: "时长", value: AppState.formatDuration(session.duration))
                            SmallMetric(title: "最高", value: String(format: "%.1f km/h", session.maxSpeed))
                            SmallMetric(title: "平均", value: String(format: "%.1f km/h", session.averageSpeed))
                            SmallMetric(title: "距离", value: String(format: "%.1f km", session.distance / 1000.0))
                        }
                    }
                    .padding(14)
                    .liquidGlass(radius: 22, fill: .ultraThinMaterial)

                    // 缩略地图
                    if let region = session.region(), session.coordinates().count >= 2 {
                        MiniMapView(region: region, coordinates: session.coordinates())
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
                    }

                    // 车速图表
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                            Text("车速曲线")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)

                        SpeedChartView(points: session.speedSeries())
                            .frame(height: 160)
                    }
                    .padding(14)
                    .liquidGlass(radius: 22, fill: .ultraThinMaterial)

                    // 删除按钮
                    Button(role: .destructive) {
                        dataStore.delete(session)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("删除此记录")
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .foregroundStyle(.red)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.1)))
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SmallMetric: View {
    var title: String
    var value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 小型地图：显示完整轨迹
private struct MiniMapView: View {
    var region: MKCoordinateRegion
    var coordinates: [CLLocationCoordinate2D]

    var body: some View {
        Map(position: .constant(.region(region))) {
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
            if let first = coordinates.first {
                Marker("起点", coordinate: first)
                    .tint(.green)
            }
            if let last = coordinates.last {
                Marker("终点", coordinate: last)
                    .tint(.red)
            }
        }
        .mapStyle(.standard(emphasis: .muted))
    }
}

/// 简单的车速折线图（使用 SwiftUI Path 手绘，不依赖第三方
private struct SpeedChartView: View {
    var points: [(time: TimeInterval, speed: Double)]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // 背景网格
            Path { p in
                for i in 0...4 {
                    let y = CGFloat(i) * h / 4.0
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: w, y: y))
                }
            }
            .stroke(Color.white.opacity(0.12), lineWidth: 1)

            if points.count >= 2 {
                let maxTime = points.last!.time
                let maxSpeed = max(10, points.map(\.speed).max() ?? 0)

                let line = Path { p in
                    for (idx, point) in points.enumerated() {
                        let x = maxTime > 0 ? CGFloat(point.time / maxTime) * w : CGFloat(idx) / CGFloat(points.count - 1) * w
                        let y = h - CGFloat(point.speed / maxSpeed) * h
                        if idx == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }

                // 填充渐变
                let fill = Path { p in
                    for (idx, point) in points.enumerated() {
                        let x = maxTime > 0 ? CGFloat(point.time / maxTime) * w : CGFloat(idx) / CGFloat(points.count - 1) * w
                        let y = h - CGFloat(point.speed / maxSpeed) * h
                        if idx == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }

                fill.fill(LinearGradient(colors: [.cyan.opacity(0.45), .cyan.opacity(0.05)],
                                         startPoint: .top, endPoint: .bottom))
                line.stroke(.cyan, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            } else {
                Text("暂无数据")
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(session: Session())
    }
}
