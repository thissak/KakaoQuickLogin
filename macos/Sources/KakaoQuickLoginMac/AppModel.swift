import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var status = AppStatus(
        tone: .ready,
        title: "준비됨",
        message: "카카오톡을 실행하고 안전하게 로그인합니다."
    )
    @Published private(set) var isBusy = false
    @Published var passwordPrompt: PasswordPromptMode?

    private let keychain = KeychainStore()
    private let automation = KakaoTalkAutomation()
    private var didStart = false

    func start() {
        guard !didStart else { return }
        didStart = true

        Task {
            do {
                let passwordExists = try await keychain.hasPassword()
                if passwordExists {
                    await performLogin()
                } else {
                    passwordPrompt = .initial
                    status = AppStatus(
                        tone: .ready,
                        title: "최초 설정",
                        message: "카카오톡 비밀번호를 키체인에 한 번 저장해 주세요."
                    )
                }
            } catch {
                show(error)
            }
        }
    }

    func login() {
        guard !isBusy else { return }
        Task { await performLogin() }
    }

    func requestPasswordReset() {
        guard !isBusy else { return }
        passwordPrompt = .reset
    }

    func savePassword(_ password: String, mode: PasswordPromptMode) {
        guard !password.isEmpty, !isBusy else { return }
        passwordPrompt = nil

        Task {
            isBusy = true
            status = AppStatus(
                tone: .working,
                title: "저장 중",
                message: "macOS 키체인에 비밀번호를 저장하고 있습니다."
            )

            do {
                try await keychain.savePassword(password)
                isBusy = false

                if mode == .initial {
                    await performLogin()
                } else {
                    status = AppStatus(
                        tone: .success,
                        title: "저장 완료",
                        message: "새 비밀번호를 macOS 키체인에 저장했습니다."
                    )
                }
            } catch {
                isBusy = false
                show(error)
            }
        }
    }

    func forgetPassword() {
        guard !isBusy else { return }

        Task {
            isBusy = true
            defer { isBusy = false }

            do {
                try await keychain.deletePassword()
                status = AppStatus(
                    tone: .success,
                    title: "삭제 완료",
                    message: "이 Mac의 키체인에서 저장된 비밀번호를 삭제했습니다."
                )
            } catch {
                show(error)
            }
        }
    }

    func openAccessibilitySettings() {
        automation.openAccessibilitySettings()
    }

    private func performLogin() async {
        guard !isBusy else { return }
        isBusy = true
        status = AppStatus(
            tone: .working,
            title: "확인 중",
            message: "카카오톡을 열고 로그인 화면을 확인하고 있습니다. 최대 20초까지 걸릴 수 있습니다."
        )

        do {
            guard var passwordData = try await keychain.loadPassword() else {
                isBusy = false
                passwordPrompt = .initial
                status = AppStatus(
                    tone: .ready,
                    title: "비밀번호 필요",
                    message: "카카오톡 비밀번호를 키체인에 저장해 주세요."
                )
                return
            }
            defer { passwordData.resetBytes(in: 0..<passwordData.count) }

            guard let password = String(data: passwordData, encoding: .utf8) else {
                throw KeychainError.invalidPasswordEncoding
            }

            let outcome = try await automation.login(password: password)
            isBusy = false

            switch outcome {
            case .submitted:
                status = AppStatus(
                    tone: .success,
                    title: "로그인 요청 완료",
                    message: "카카오톡에 비밀번호를 입력하고 로그인 버튼을 눌렀습니다."
                )
            case .alreadyLoggedIn:
                status = AppStatus(
                    tone: .success,
                    title: "이미 로그인됨",
                    message: "카카오톡이 이미 로그인된 상태여서 입력하지 않았습니다."
                )
            case .loginWindowNotFound:
                status = AppStatus(
                    tone: .warning,
                    title: "입력하지 않음",
                    message: "카카오톡 로그인 창을 찾지 못했습니다. 카카오톡을 직접 열어 로그인 화면을 띄운 뒤 다시 시도해 주세요."
                )
            case .passwordFieldNotFound:
                status = AppStatus(
                    tone: .warning,
                    title: "입력하지 않음",
                    message: "로그인 창은 찾았지만 비밀번호 입력란을 확인하지 못했습니다. 카카오톡 화면이 변경되었을 수 있습니다."
                )
            }
        } catch {
            isBusy = false
            show(error)
        }
    }

    private func show(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        status = AppStatus(
            tone: .error,
            title: "완료하지 못함",
            message: message
        )
    }
}

enum PasswordPromptMode: String, Identifiable {
    case initial
    case reset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .initial: return "비밀번호 저장"
        case .reset: return "비밀번호 변경"
        }
    }
}

struct AppStatus {
    let tone: StatusTone
    let title: String
    let message: String
}

enum StatusTone {
    case ready
    case working
    case success
    case warning
    case error
}
