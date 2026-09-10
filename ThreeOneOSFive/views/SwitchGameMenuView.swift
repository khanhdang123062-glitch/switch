import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SwitchGameMenuView: View {
    @EnvironmentObject private var appState: AppState
    let app: InstalledApp
    @StateObject private var patchStore = PatchProjectStore()

    @State private var presets: [TogglePreset] = []
    @State private var isPatching = false
    @State private var patchError: String?
    @State private var showSuccess = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                gameHeader

                // Tab content
                if selectedTab == 0 {
                    ScrollView {
                        VStack(spacing: 16) {
                            patchSection
                            fovSection
                        }
                        .padding(16)
                    }
                } else {
                    importSection
                }

                // Tab bar
                tabBar
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            if !appState.exploitStatus.isSuccess {
                HStack(spacing: 10) {
                    if appState.kernelExploitRunning {
                        ProgressView().tint(.orange).scaleEffect(0.8)
                    } else {
                        Image(systemName: "shield.slash.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                    Text(appState.kernelExploitRunning
                         ? "Đang kích hoạt exploit..."
                         : "Exploit chưa active — chức năng patch bị khoá")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.12))
            }
        }
        .onAppear {
            presets = TogglePresetStore.presets(for: app.bundleID)
            patchStore.reload()
        }
        .alert("Đã mod thành công!", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        }
        .alert("Lỗi", isPresented: Binding(
            get: { patchError != nil },
            set: { if !$0 { patchError = nil } }
        )) {
            Button("OK", role: .cancel) { patchError = nil }
        } message: { Text(patchError ?? "") }
    }

    // MARK: - Header

    private var gameHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Group {
                    if let icon = app.icon {
                        Image(uiImage: icon)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.1))
                            .overlay(Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white.opacity(0.4)))
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(app.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Ứng dụng: \(app.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Bundle: \(app.bundleID)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
                Spacer()
            }

            // Open game button
            Button(action: openApp) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Chạy")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(presets.filter(\.isEnabled).isEmpty ? Color.gray : Color.green)
                    .frame(width: 8, height: 8)
                Text(presets.filter(\.isEnabled).isEmpty ? "Patch chưa áp dụng" : "Patch đã bật")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color.white.opacity(0.1)), alignment: .bottom)
    }

    // MARK: - Patch Section

    private var patchSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("PATCH")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                // HACK button
                Button(action: applyHack) {
                    HStack(spacing: 6) {
                        if isPatching {
                            ProgressView().tint(.white).controlSize(.small)
                        } else {
                            Image(systemName: "bolt.fill").font(.system(size: 12, weight: .bold))
                        }
                        Text("HACK").font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(presets.filter(\.isEnabled).isEmpty ? Color.gray : Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isPatching || presets.filter(\.isEnabled).isEmpty || !appState.exploitStatus.isSuccess)
            }
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(1...5, id: \.self) { id in
                    let preset = presets.first { $0.id == id }
                    let hasFile = preset != nil
                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(toggleName(id))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(hasFile ? .white : .white.opacity(0.35))
                                Text(hasFile ? (preset?.fileType.uppercased() ?? "") : "Chưa có file — vào tab Nhập file")
                                    .font(.caption2)
                                    .foregroundStyle(hasFile ? Color.green.opacity(0.8) : .white.opacity(0.2))
                            }
                            Spacer()
                            if hasFile, let idx = presets.firstIndex(where: { $0.id == id }) {
                                Toggle("", isOn: Binding(
                                    get: { presets[idx].isEnabled },
                                    set: { val in
                                        presets[idx].isEnabled = val
                                        TogglePresetStore.save(presets, for: app.bundleID)
                                    }
                                ))
                                .labelsHidden()
                                .tint(.green)
                            } else {
                                Toggle("", isOn: .constant(false))
                                    .labelsHidden()
                                    .disabled(true)
                                    .opacity(0.25)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.06))

                        if id < 5 {
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 16)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - FOV Section

    private var fovSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("FOV")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
            .padding(.bottom, 10)

            @State var fovValue: Double = {
                let v = UserDefaults.standard.double(forKey: "fov.\(app.bundleID)")
                return v == 0 ? 50 : v
            }()

            VStack(spacing: 12) {
                HStack {
                    Text("Field of View")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(fovValue))px")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                }
                Slider(value: $fovValue, in: 1...200, step: 1) { Text("FOV") }
                    minimumValueLabel: { Text("1").font(.caption).foregroundStyle(.white.opacity(0.4)) }
                    maximumValueLabel: { Text("200").font(.caption).foregroundStyle(.white.opacity(0.4)) }
                    .tint(.blue)
                    .onChange(of: fovValue) { val in
                        UserDefaults.standard.set(val, forKey: "fov.\(app.bundleID)")
                    }
                HStack {
                    ForEach([50, 100, 141, 200], id: \.self) { val in
                        Button { fovValue = Double(val) } label: {
                            Text("\(val)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Int(fovValue) == val ? .white : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .frame(height: 30)
                                .background(Int(fovValue) == val ? Color.blue : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Import Section

    private var importSection: some View {
        SwitchImportView(app: app, patchStore: patchStore, presets: $presets)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabItem(index: 0, icon: "square.grid.2x2.fill", label: "Patch")
            tabItem(index: 1, icon: "square.and.arrow.down.fill", label: "Nhập file")
        }
        .background(Color.black.opacity(0.5))
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color.white.opacity(0.1)), alignment: .top)
    }

    private func tabItem(index: Int, icon: String, label: String) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == index ? .green : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Toggle Names
    // *** ĐẶT TÊN TOGGLE CHO TỪNG GAME Ở ĐÂY ***
    private func toggleName(_ id: Int) -> String {
        switch app.bundleID {
        case "com.garena.game.kgvn": // Liên Quân
            switch id {
            case 1: return "hack map" // Đổi tên ở đây
            case 2: return "unlock skin"
            case 3: return "cam xa" 
            default: return "Toggle \(id)"
            }
        case "com.dts.freefireth", "com.dts.freefiremax": // Free Fire
            switch id {
            case 1: return "Toggle 1"
            case 2: return "Toggle 2"
            case 3: return "Toggle 3"
            case 4: return "Toggle 4"
            case 5: return "Toggle 5"
            default: return "Toggle \(id)"
            }
        case "vn.vng.pubgmobile": // PUBG
            switch id {
            case 1: return "Toggle 1"
            case 2: return "Toggle 2"
            case 3: return "Toggle 3"
            case 4: return "Toggle 4"
            case 5: return "Toggle 5"
            default: return "Toggle \(id)"
            }
        case "com.gameversestudio.modern.ops.fps.gun.games": // Modern Ops
            switch id {
            case 1: return "Toggle 1"
            case 2: return "Toggle 2"
            case 3: return "Toggle 3"
            case 4: return "Toggle 4"
            case 5: return "Toggle 5"
            default: return "Toggle \(id)"
            }
        default:
            return "Toggle \(id)"
        }
    }

    // MARK: - Actions

    private func applyHack() {
        guard !isPatching else { return }
        let active = presets.filter(\.isEnabled)
        guard !active.isEmpty else { return }
        isPatching = true
        DispatchQueue.global(qos: .userInitiated).async {
            var errors: [String] = []
            for preset in active {
                let fileURL = URL(fileURLWithPath: preset.filePath)
                guard FileManager.default.fileExists(atPath: preset.filePath) else {
                    errors.append("Toggle \(preset.id): file không tồn tại"); continue
                }
                if preset.fileType == "zip" {
                    do { _ = try ZipPatchService.apply(zipURL: fileURL, bundleID: app.bundleID) }
                    catch { errors.append("\(error.localizedDescription)") }
                } else {
                    patchStore.importPackage(at: fileURL)
                }
            }
            DispatchQueue.main.async {
                isPatching = false
                if errors.isEmpty { showSuccess = true }
                else { patchError = errors.joined(separator: "\n") }
            }
        }
    }

    private func openApp() {
        let sel = NSSelectorFromString("defaultWorkspace")
        guard let cls = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
              cls.responds(to: sel),
              let workspace = cls.perform(sel)?.takeUnretainedValue() as? NSObject else { return }
        let openSel = NSSelectorFromString("openApplicationWithBundleID:")
        if workspace.responds(to: openSel) { _ = workspace.perform(openSel, with: app.bundleID) }
    }
}
