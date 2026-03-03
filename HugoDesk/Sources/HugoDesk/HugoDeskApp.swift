import SwiftUI

@main
struct HugoDeskApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("HugoDesk 博客桌面端") {
            RootView(viewModel: viewModel)
                .frame(minWidth: 1200, minHeight: 760)
        }
    }
}
