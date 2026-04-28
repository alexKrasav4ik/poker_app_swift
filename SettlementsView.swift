import SwiftUI

struct SettlementsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var gameStore: GameStore

    @State private var showConfirmSettlement = false
    @State private var presentedSettlement: SettlementRecord?
    @State private var showAlert = false
    @State private var alertBody = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let pending = gameStore.unsettledSessions.count
                    if pending == 0 {
                        Text("Нет нерассчитанных игр — залейте новые или все уже учтены в расчётах.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Нерассчитанных игр: \(pending). Расчёт учтёт все сразу и сгенерирует переводы по суммарному нетто по никам.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("Сделать расчёт") {
                        if gameStore.unsettledSessions.isEmpty {
                            alertBody = "Нечего рассчитывать."
                            showAlert = true
                        } else {
                            showConfirmSettlement = true
                        }
                    }
                    .disabled(gameStore.unsettledSessions.isEmpty)
                }

                Section("Список игр (ID и статус)") {
                    if gameStore.sessions.isEmpty {
                        Text("Игр пока нет.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(gameStore.sessions) { session in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(session.id.uuidString)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)

                                HStack {
                                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                    Spacer()
                                    statusBadge(settled: session.isSettled)
                                }

                                Text("\(session.rows.count) игроков")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("История расчётов") {
                    if gameStore.settlements.isEmpty {
                        Text("Расчётов ещё не было.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(gameStore.settlements) { record in
                            Button {
                                presentedSettlement = record
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(record.transfers.count) переводов · игр: \(record.settledSessionIds.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Игры и расчёты")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Выйти") {
                        authViewModel.logout()
                    }
                }
            }
            .confirmationDialog(
                "Сделать расчёт по \(gameStore.unsettledSessions.count) играм?",
                isPresented: $showConfirmSettlement,
                titleVisibility: .visible
            ) {
                Button("Сгенерировать переводы и пометить игры") {
                    if let record = gameStore.performSettlement() {
                        presentedSettlement = record
                    } else {
                        alertBody = "Не удалось выполнить расчёт."
                        showAlert = true
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все нерассчитанные игры станут «рассчитанными». Переводы считаются по сумме результатов по никам.")
            }
            .sheet(item: $presentedSettlement) { record in
                settlementSheet(record)
            }
            .alert("Сообщение", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertBody)
            }
        }
    }

    @ViewBuilder
    private func statusBadge(settled: Bool) -> some View {
        if settled {
            Text("Расчитано")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
        } else {
            Text("Нет")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func settlementSheet(_ record: SettlementRecord) -> some View {
        NavigationStack {
            List {
                if record.transfers.isEmpty {
                    Section {
                        Text("Переводов нет (суммарные нетто по никам сошлись в ноль). Игры помечены как рассчитанные.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Кто кому сколько (у.е.)") {
                        ForEach(record.transfers) { t in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(t.fromNickname) → \(t.toNickname)")
                                    .font(.headline)
                                Text(UEFormat.string(for: t.amount))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section("Игры в этом расчёте") {
                    ForEach(record.settledSessionIds, id: \.self) { sid in
                        Text(sid.uuidString)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Расчёт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Закрыть") {
                        presentedSettlement = nil
                    }
                }
            }
        }
    }
}
