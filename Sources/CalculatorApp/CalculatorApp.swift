import SwiftUI

@main
struct CalculatorApp: App {
    @StateObject private var viewModel = CalculatorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 380, idealWidth: 420, minHeight: 620, idealHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
