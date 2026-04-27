import Foundation
import Combine

final class AuthViewModel: ObservableObject {
    @Published private(set) var users: [AppUser] = []
    @Published private(set) var currentUser: AppUser?
    @Published var errorMessage: String?

    private let usersKey = "poker_app_users"
    private let currentUserKey = "poker_app_current_user_id"

    init() {
        loadUsers()
        restoreSession()
    }

    var isLoggedIn: Bool {
        currentUser != nil
    }

    func login(username: String, password: String) {
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedUsername.isEmpty, !normalizedPassword.isEmpty else {
            errorMessage = "Введите логин и пароль."
            return
        }

        guard let user = users.first(where: { $0.username == normalizedUsername && $0.password == normalizedPassword }) else {
            errorMessage = "Неверный логин или пароль."
            return
        }

        errorMessage = nil
        currentUser = user
        saveCurrentUserId(user.id)
    }

    func register(username: String, password: String) {
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedUsername.isEmpty, !normalizedPassword.isEmpty else {
            errorMessage = "Логин и пароль не могут быть пустыми."
            return
        }

        guard users.first(where: { $0.username == normalizedUsername }) == nil else {
            errorMessage = "Пользователь с таким логином уже есть."
            return
        }

        let newUser = AppUser(id: UUID(), username: normalizedUsername, password: normalizedPassword)
        users.append(newUser)
        saveUsers()

        errorMessage = nil
        currentUser = newUser
        saveCurrentUserId(newUser.id)
    }

    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }

    private func loadUsers() {
        guard let data = UserDefaults.standard.data(forKey: usersKey) else {
            users = []
            return
        }

        users = (try? JSONDecoder().decode([AppUser].self, from: data)) ?? []
    }

    private func saveUsers() {
        guard let data = try? JSONEncoder().encode(users) else { return }
        UserDefaults.standard.set(data, forKey: usersKey)
    }

    private func saveCurrentUserId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: currentUserKey)
    }

    private func restoreSession() {
        guard
            let savedId = UserDefaults.standard.string(forKey: currentUserKey),
            let uuid = UUID(uuidString: savedId),
            let user = users.first(where: { $0.id == uuid })
        else {
            return
        }

        currentUser = user
    }
}
