import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var gameStore: GameStore

    var body: some View {
        NavigationStack {
            List {
                Section("Общая статистика") {
                    statRow(title: "Залитых игр (сессий)", value: "\(gameStore.stats.sessionsCount)")
                    statRow(title: "Строк игроков всего", value: "\(gameStore.stats.playerRowsCount)")
                    statRow(title: "Сумма результатов по строкам", value: formatAmount(gameStore.stats.totalResult))
                    statRow(title: "Средний результат на строку", value: formatAmount(gameStore.stats.averageResultPerRow))
                    statRow(title: "Максимальный выигрыш (строка)", value: formatAmount(gameStore.stats.maxWin))
                    statRow(title: "Максимальный проигрыш (строка)", value: formatAmount(gameStore.stats.maxLoss))
                }

                Section("Все залитые игры") {
                    if gameStore.sessions.isEmpty {
                        Text("Пока никто не заливал игры.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(gameStore.sessions) { session in
                            DisclosureGroup {
                                ForEach(session.rows) { row in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(row.nickname)
                                                .font(.headline)
                                            Spacer()
                                            Text(formatAmount(row.result))
                                                .foregroundStyle(row.result >= 0 ? .green : .red)
                                        }
                                        Text("Закуп: \(formatAmount(row.buyIn)) | Выкуп: \(formatAmount(row.cashOut))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(session.rows.count) игроков · \(session.isSettled ? "рассчитано" : "нет расчёта")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Статистика")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Выйти") {
                        authViewModel.logout()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func formatAmount(_ value: Double) -> String {
        UEFormat.string(for: value)
    }
}
