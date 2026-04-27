import SwiftUI

@main
struct PokerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var gameStore = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(gameStore)
        }
    }
}
