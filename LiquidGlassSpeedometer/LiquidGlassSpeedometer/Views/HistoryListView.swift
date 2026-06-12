import SwiftUI
import CoreData

/// 历史记录列表
struct HistoryListView: View {
    @EnvironmentObject var dataStore: DataStore
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.startTime, ascending: false)],
        animation: .default
    ) var sessions: FetchedResults<Session>

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.35),
                         Color(red: 0.12, green: 0.14, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if sessions.isEmpty {
                ContentUnavailableView("暂无记录", systemImage: "clock.arrow.circlepath", description: Text("开始记录后将在此显示"))
                    .foregroundStyle(.white)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sessions, id: \.self) { session in
                            NavigationLink {
                                HistoryDetailView(session: session)
                            } label: {
                                HistoryRow(session: session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
        .navigationTitle("历史记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }
}

private struct HistoryRow: View {
    @ObservedObject var session: Session

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title ?? "未知")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 10) {
                    Label("\(Int(session.maxSpeed.rounded())) km/h", systemImage: "flame.fill")
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
    NavigationStack {
        HistoryListView()
            .environmentObject(DataStore.shared)
    }
}
