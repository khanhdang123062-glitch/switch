import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var tabNavigation: AppTabNavigationState
    @AppStorage(FeatureVisibility.cleanerStorageKey) private var cleanerEnabled = true
    @AppStorage(FeatureVisibility.wallpapersStorageKey) private var wallpapersEnabled = true

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-files-tab") {
            initialTab = AppSection.files.rawValue
        } else if arguments.contains("--simulate-patch-tab") {
            initialTab = AppSection.patches.rawValue
        } else if arguments.contains("--simulate-cleaner-tab") {
            initialTab = AppSection.cleaner.rawValue
        } else if arguments.contains("--simulate-wallpaper-tab") {
            initialTab = AppSection.wallpapers.rawValue
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        SwitchMainView()
            .tint(.green)
            .imageScale(.small)
            .onChange(of: patchDraftCoordinator.request?.id) { requestID in
                if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
            }
    }
}
