import SwiftUI
import UIKit

private struct SwitchGame: Identifiable {
    let id = UUID()
    let name: String
    let bundleID: String
    let icon: UIImage?
}

private let switchGames: [SwitchGame] = [
    SwitchGame(name: "Liên Quân Mobile", bundleID: "com.garena.game.kgvn",
               icon: BundledIcons.image(for: "com.garena.game.kgvn")),
    SwitchGame(name: "Free Fire", bundleID: "com.dts.freefireth",
               icon: BundledIcons.image(for: "com.dts.freefireth")),
    SwitchGame(name: "Free Fire Max", bundleID: "com.dts.freefiremax",
               icon: BundledIcons.image(for: "com.dts.freefiremax")),
    SwitchGame(name: "PUBG Mobile", bundleID: "vn.vng.pubgmobile",
               icon: BundledIcons.image(for: "vn.vng.pubgmobile")),
    SwitchGame(name: "Modern Ops FPS", bundleID: "com.gameversestudio.modern.ops.fps.gun.games",
               icon: nil),
]

struct SwitchMainView: View {
    @EnvironmentObject private var appState: AppState

    // Container lookups can be expensive and must not run while SwiftUI is
    // evaluating `body`. Keep the resolved paths in state instead.
    @State private var appContainerPaths: [String: String] = [:]
    @State private var isLoadingAppPaths = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.08).ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView
                    statusCard.padding(.horizontal, 16).padding(.top, 12)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Chọn game")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Patch và menu sẽ được áp dụng trước khi mở game.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(switchGames) { game in
                                let containerPath = appContainerPaths[game.bundleID]
                                let installed = containerPath != nil

                                NavigationLink(destination: SwitchGameMenuView(
                                    app: InstalledApp(
                                        bundleID: game.bundleID,
                                        name: game.name,
                                        containerPath: containerPath ?? "",
                                        version: "DS",
                                        icon: game.icon
                                    )
                                )) {
                                    SwitchGameRowView(
                                        name: game.name,
                                        bundleID: game.bundleID,
                                        icon: game.icon,
                                        isInstalled: installed
                                    )
                                }
                                .buttonStyle(.plain)
                                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await loadAppContainerPaths()
            }
            .refreshable {
                await loadAppContainerPaths()
            }
        }
    }

    private func loadAppContainerPaths() async {
        guard !isLoadingAppPaths else { return }

        isLoadingAppPaths = true
        defer { isLoadingAppPaths = false }

        // Pass only Sendable values into the detached task. `SwitchGame`
        // contains UIImage and should not cross concurrency domains.
        let bundleIDs = switchGames.map(\.bundleID)

        // ContainerStore performs filesystem/container discovery. Do it away
        // from the main actor so the initial SwiftUI frame can render.
        let paths = await Task.detached(priority: .userInitiated) {
            var result: [String: String] = [:]

            for bundleID in bundleIDs {
                if let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID) {
                    result[bundleID] = path
                }
            }

            return result
        }.value

        // `loadAppContainerPaths` is called from a SwiftUI task and therefore
        // resumes on the view's actor before mutating State.
        appContainerPaths = paths
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Switch")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                Text("v1.0 · iOS \(AppInfo.osVersion)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            NavigationLink(destination: SwitchSettingsView()) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(statusTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Circle().fill(statusColor).frame(width: 8, height: 8)
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusColor: Color {
        appState.exploitStatus.isSuccess ? .green : .orange
    }
    private var statusIcon: String {
        appState.exploitStatus.isSuccess ? "checkmark.shield.fill" : "shield.slash.fill"
    }
    private var statusTitle: String {
        if appState.kernelExploitRunning { return "Đang kích hoạt..." }
        return appState.exploitStatus.isSuccess ? "Sẵn sàng" : "Chưa kích hoạt"
    }
    private var statusSubtitle: String {
        if appState.kernelExploitRunning { return "Vui lòng chờ..." }
        return appState.exploitStatus.isSuccess
            ? "Exploit đã active — có thể patch game"
            : "Exploit chưa chạy — một số chức năng bị giới hạn"
    }
}
