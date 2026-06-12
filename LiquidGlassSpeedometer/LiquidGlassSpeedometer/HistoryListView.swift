import SwiftUI

struct HistoryListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showConfirm: Bool = false
    @State private var sessionToDelete: Session?
    @State private var sessionToInspect: Session?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.18, blue: 0.35),
                             Color(red: 0.12, green: 0.14, blue: 0.28)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if dataStore.sessions.isEmpty {
                    ContentUnavailableView(
                        "暂无记录",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("在码表页点击开始记录")
                    )
                    .foregroundStyle(.white)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(dataStore.sessions) { session in
                                NavigationLink {
                                    HistoryDetailView(session: session)
                                } label: {
                                    row(session)
                                }
                                .buttonStyle(.plain)
                                .onLongPressGesture(minimumDuration: 0.6) {
                                    sessionToInspect = session
                                }
                                .contextMenu {
                                    Button {
                                        sessionToInspect = session
                                    } label: {
                                        Label("查看记录点", systemImage: "list.bullet.rectangle.portrait")
                                    }
                                    Button(role: .destructive) {
                                        sessionToDelete = session
                                        showConfirm = true
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sessionToInspect) { session in
                TrackPointsSheet(session: session)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(.dark)
            }
            .alert("确认删除", isPresented: $showConfirm) {
                Button("删除", role: .destructive) {
                    if let s = sessionToDelete { dataStore.delete(s) }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("此操作不可撤销")
            }
        }
    }

    private func row(_ session: Session) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppState.dateFormatter.string(from: session.startTime))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 10) {
                    Label(String(format: "最高 %.1f km/h", session.maxSpeed), systemImage: "flame.fill")
                    Label(AppState.formatDuration(session.duration), systemImage: "stopwatch.fill")
                    Label(String(format: "%d 个点", session.locations.count), systemImage: "mappin.circle")
                }
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(14)
        .liquidGlass(radius: 18, fill: .ultraThinMaterial)
    }
}

/// 记录点详情底页：列出每个记录点的时间 / 速度 / 海拔 / 坐标
private struct TrackPointsSheet: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.18, blue: 0.35),
                             Color(red: 0.12, green: 0.14, blue: 0.28)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if session.locations.isEmpty {
                    ContentUnavailableView("无记录点", systemImage: "mappin.slash",
                                           description: Text("本次记录未采集到位置数据"))
                        .foregroundStyle(.white)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(session.locations.enumerated()), id: \.element.id) { idx, pt in
                                let timeOffset = pt.timestamp.timeIntervalSince(session.startTime)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("#\(idx + 1)")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.cyan)
                                        Text(String(format: "T+%.0fs", timeOffset))
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.6))
                                        Spacer()
                                        Text(String(format: "%.1f km/h", pt.speed))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    HStack(spacing: 12) {
                                        Label(String(format: "%.0f m", pt.altitude), systemImage: "mountain.2.fill")
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.8))
                                        Label(String(format: "%.5f, %.5f", pt.latitude, pt.longitude),
                                              systemImage: "mappin.and.ellipse")
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.7))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.08)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("记录点详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    HistoryListView()
        .environmentObject(DataStore.shared)
}
