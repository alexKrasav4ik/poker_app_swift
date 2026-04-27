import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AddGameView()
                .tabItem {
                    Label("Добавить", systemImage: "plus.circle")
                }

            StatisticsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.doc.horizontal")
                }
        }
    }
}
