import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator

    var body: some View {
        SwitchMainView()
            .tint(.green)
    }
}
