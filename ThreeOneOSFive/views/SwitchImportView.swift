import SwiftUI
import UniformTypeIdentifiers

struct SwitchImportView: View {
    let app: InstalledApp
    @ObservedObject var patchStore: PatchProjectStore
    @Binding var presets: [TogglePreset]

    @State private var showFilePicker = false
    @State private var selectedToggleID: Int?
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack {
                    Text("Chọn toggle → nhập file cho toggle đó")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                ForEach(1...5, id: \.self) { id in
                    let preset = presets.first { $0.id == id }
                    importRow(id: id, preset: preset)
                }
            }
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showFilePicker) {
            FileDocumentPicker(
                allowedContentTypes: [UTType(filenameExtension: "3105") ?? .data, .data],
                copiesSelectedDocument: true,
                allowsMultipleSelection: false,
                onSelection: { result in
                    showFilePicker = false
                    handleImport(result: result)
                },
                onCancel: {
                    showFilePicker = false
                    selectedToggleID = nil
                }
            )
            .ignoresSafeArea()
        }
        .alert("Lỗi", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .overlay {
            if isImporting {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().tint(.white)
                        Text("Đang lưu...").foregroundStyle(.white).font(.subheadline)
                    }
                    .padding(24)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func importRow(id: Int, preset: TogglePreset?) -> some View {
        HStack(spacing: 14) {
            // Toggle number
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(preset != nil ? Color.green.opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                Text("\(id)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(preset != nil ? .green : .white.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(preset?.name ?? "Toggle \(id)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(preset != nil ? .white : .white.opacity(0.4))
                Text(preset != nil ? preset!.fileName : "Chưa có file")
                    .font(.caption2)
                    .foregroundStyle(preset != nil ? Color.green.opacity(0.7) : .white.opacity(0.2))
                    .lineLimit(1)
            }

            Spacer()

            // Import / Change button
            Button {
                selectedToggleID = id
                showFilePicker = true
            } label: {
                Text(preset != nil ? "Đổi" : "Nhập")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(preset != nil ? Color.green : Color.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Delete button
            if preset != nil {
                Button {
                    deletePreset(id: id)
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func handleImport(result: Result<[URL], Error>) {
        guard let toggleID = selectedToggleID else { return }
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            selectedToggleID = nil
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            isImporting = true
            let existingName = presets.first(where: { $0.id == toggleID })?.name ?? "Toggle \(toggleID)"
            let fileExt = url.pathExtension.lowercased() == "zip" ? "zip" : "3105"
            let fileName = url.lastPathComponent
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let cachedPath = try TogglePresetStore.cacheFile(
                        sourceURL: url, bundleID: app.bundleID,
                        toggleID: toggleID, fileType: fileExt
                    )
                    let preset = TogglePreset(
                        id: toggleID, name: existingName,
                        fileName: fileName, fileType: fileExt,
                        filePath: cachedPath
                    )
                    TogglePresetStore.add(preset: preset, for: app.bundleID)
                    DispatchQueue.main.async {
                        isImporting = false
                        selectedToggleID = nil
                        presets = TogglePresetStore.presets(for: app.bundleID)
                    }
                } catch {
                    DispatchQueue.main.async {
                        isImporting = false
                        selectedToggleID = nil
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func deletePreset(id: Int) {
        TogglePresetStore.remove(id: id, for: app.bundleID)
        presets = TogglePresetStore.presets(for: app.bundleID)
    }
}
