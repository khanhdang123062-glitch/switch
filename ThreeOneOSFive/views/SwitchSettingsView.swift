import SwiftUI

struct SwitchSettingsView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @State private var showLogs = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Thiết bị", value: AppInfo.displayMachineName)
                LabeledContent("iOS", value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                HStack {
                    Text("Trạng thái")
                    Spacer()
                    Text(appState.exploitStatus.isSuccess ? "Hỗ trợ" : "Không hỗ trợ")
                        .foregroundStyle(appState.exploitStatus.isSuccess ? .green : .red)
                }
            } header: {
                Text("Thiết bị")
            }

            Section {
                Button {
                    showLogs = true
                } label: {
                    Label("Xem logs", systemImage: "apple.terminal")
                }
            } header: {
                Text("Debug")
            }

            Section {
                Link("GitHub", destination: URL(string: "https://github.com/YangJiii/3105")!)
            } header: {
                Text("Thông tin")
            }
        }
        .navigationTitle("Cài đặt")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogs) { LogView() }
    }
}
