import SwiftUI
import MapKit
import CoreLocation

/// 地图界面：显示本次路径轨迹
/// 说明：为了避免强依赖第三方 SDK 时的编译问题，这里默认使用 Apple MapKit 作为基础实现，
/// 同时预留了 AMap（高德地图）集成的 API key 配置入口，用户在引入 AMap SDK 后可直接替换。
struct MapTrackView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var loc: LocationManager

    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.908, longitude: 116.397),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    @State private var polylineCoords: [CLLocationCoordinate2D] = []

    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.35),
                         Color(red: 0.12, green: 0.14, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Map(position: .constant(.region(region))) {
                // 用户位置
                UserAnnotation()

                // 轨迹 Polyline
                if polylineCoords.count >= 2 {
                    MapPolyline(coordinates: polylineCoords)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                }
            }
            .mapStyle(.standard(emphasis: .muted))
            .ignoresSafeArea(edges: .bottom)

            // 顶部 HUD：速度 / 海拔 / 时间（Liquid glass 风格
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    HUDCard(title: "速度", value: String(format: "%.0f km/h", app.currentSpeed), systemImage: "gauge.with.dots.needle.bottom.50percent")
                    HUDCard(title: "海拔", value: String(format: "%.0f m", app.altitude), systemImage: "mountain.2.fill")
                    HUDCard(title: "时长", value: AppState.formatDuration(app.elapsed), systemImage: "stopwatch.fill")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }
            .padding(.top, 8)
        }
        .onAppear {
            loc.start()
            if let loc2d = loc.lastLocation {
                region.center = loc2d.coordinate
            }
        }
        .onChange(of: loc.lastLocation) { newValue in
            guard let newValue else { return }
            region.center = newValue.coordinate
            // 平滑拉取当前会话坐标
            if let session = app.currentSession {
                polylineCoords = session.coordinates()
            } else {
                if !polylineCoords.isEmpty && !app.isRecording {
                    // 已停止
                }
            }
        }
        .navigationTitle("地图")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HUDCard: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .liquidGlass(radius: 16, fill: .ultraThinMaterial)
    }
}
