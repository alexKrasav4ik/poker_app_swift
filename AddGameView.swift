import SwiftUI

private struct DraftPlayerRow: Identifiable {
    let id = UUID()
    var nickname: String = ""
    var buyInText: String = ""
    var cashOutText: String = ""
}

struct AddGameView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var gameStore: GameStore

    @State private var draftRows: [DraftPlayerRow] = [DraftPlayerRow(), DraftPlayerRow(), DraftPlayerRow()]
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Один человек заливает всю игру: добавь строки по каждому игроку (ник, закуп, выкуп), затем нажми «Залить всю игру».")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Игроки за столом") {
                    ForEach($draftRows) { $row in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Ник", text: $row.nickname)
                            TextField("Закуп", text: $row.buyInText)
                                .keyboardType(.decimalPad)
                            TextField("Выкуп", text: $row.cashOutText)
                                .keyboardType(.decimalPad)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteRows)

                    Button("Добавить строку игрока", systemImage: "plus.circle") {
                        draftRows.append(DraftPlayerRow())
                    }
                }

                Section {
                    Button("Залить всю игру") {
                        submitSession()
                    }
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Заливка игры")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Выйти") {
                        authViewModel.logout()
                    }
                }
            }
        }
    }

    private func deleteRows(at offsets: IndexSet) {
        draftRows.remove(atOffsets: offsets)
        if draftRows.isEmpty {
            draftRows = [DraftPlayerRow(), DraftPlayerRow()]
        }
    }

    private func submitSession() {
        var parsed: [(nickname: String, buyIn: Double, cashOut: Double)] = []

        for row in draftRows {
            let nick = row.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !nick.isEmpty else { continue }

            guard
                let buyIn = parseAmount(from: row.buyInText),
                let cashOut = parseAmount(from: row.cashOutText)
            else {
                statusMessage = "Проверь суммы у игрока «\(nick)»."
                return
            }

            parsed.append((nickname: nick, buyIn: buyIn, cashOut: cashOut))
        }

        guard parsed.count >= 2 else {
            statusMessage = "Нужно минимум два игрока с заполненными ником и суммами (целиком одна игра за столом)."
            return
        }

        gameStore.addSession(playerRows: parsed)

        draftRows = [DraftPlayerRow(), DraftPlayerRow(), DraftPlayerRow()]
        statusMessage = "Игра залита (\(parsed.count) игроков)."
    }

    private func parseAmount(from input: String) -> Double? {
        let normalized = input.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
