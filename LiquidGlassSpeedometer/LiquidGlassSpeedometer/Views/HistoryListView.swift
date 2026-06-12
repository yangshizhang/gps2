import SwiftUI

struct HistoryListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showConfirm: Bool = false
    @State private var sessionToDelete: Session?

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
                                .contextMenu {
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

#Preview {
    HistoryListView()
        .environmentObject(DataStore.shared)
}
