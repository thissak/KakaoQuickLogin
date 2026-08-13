import AppKit
import ApplicationServices
import Foundation

@MainActor
final class KakaoTalkAutomation {
    private let accessibility = AccessibilityClient()
    private let keyboardInput = KeyboardInput()
    private let fileManager = FileManager.default
    private let knownBundleIdentifiers = [
        "com.kakao.KakaoTalkMac",
        "com.kakao.KakaoTalk"
    ]

    func login(password: String) async throws -> LoginOutcome {
        guard accessibility.requestTrustIfNeeded() else {
            throw AccessibilityError.permissionRequired
        }

        guard let applicationURL = findInstalledApplication() else {
            throw KakaoTalkError.notInstalled
        }

        let runningApplication = try await openOrFindApplication(at: applicationURL)
        guard validate(runningApplication: runningApplication, expectedURL: applicationURL) else {
            throw KakaoTalkError.processVerificationFailed
        }

        let applicationElement = AXUIElementCreateApplication(runningApplication.processIdentifier)
        AXUIElementSetMessagingTimeout(applicationElement, 4)

        guard let passwordField = await waitForPasswordField(in: applicationElement) else {
            return outcomeWithoutPasswordField(in: applicationElement)
        }

        try await activateAndVerifyFrontmost(runningApplication)

        try accessibility.focusAndVerify(passwordField, in: applicationElement)

        if !accessibility.setPasswordValueIfAvailable(password, in: passwordField) {
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier ==
                    runningApplication.processIdentifier else {
                throw KakaoTalkError.activationFailed
            }
            try accessibility.focusAndVerify(passwordField, in: applicationElement)
            try keyboardInput.replaceFocusedText(
                password,
                in: runningApplication.processIdentifier
            )
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        guard NSWorkspace.shared.frontmostApplication?.processIdentifier ==
                runningApplication.processIdentifier else {
            throw KakaoTalkError.activationFailed
        }

        // 로그인 버튼은 비밀번호가 채워진 뒤에야 활성화되므로 입력 후에 찾는다.
        guard let loginButton = await waitForLoginButton(in: applicationElement) else {
            throw KakaoTalkError.loginButtonNotFound
        }

        try accessibility.press(loginButton)
        return .submitted
    }

    func openAccessibilitySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    /// 카카오톡이 방금 실행되었거나 창을 다시 여는 중일 수 있어 넉넉히 기다린다.
    /// Windows판(`KakaoTalkAutomation.cs`)이 프로세스와 창 등장에 각각 20초를 쓰는 것과 맞춘다.
    private func waitForPasswordField(in application: AXUIElement) async -> AXUIElement? {
        for attempt in 0..<50 {
            if let field = accessibility.securePasswordField(in: application) {
                return field
            }
            if attempt < 49 {
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
        return nil
    }

    /// 로그인 화면이 아닐 때 원인을 구분한다. Windows판의 AlreadyLoggedIn·
    /// LoginWindowNotFound·PasswordFieldNotFound 구분에 대응한다.
    private func outcomeWithoutPasswordField(in application: AXUIElement) -> LoginOutcome {
        let titles = accessibility.windowTitles(in: application)
        if titles.isEmpty {
            return .loginWindowNotFound
        }
        let hasLoginWindow = titles.contains { title in
            let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return normalized == "로그인" || normalized == "login"
        }
        return hasLoginWindow ? .passwordFieldNotFound : .alreadyLoggedIn
    }

    private func activateAndVerifyFrontmost(_ application: NSRunningApplication) async throws {
        for attempt in 0..<3 {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier ==
                application.processIdentifier {
                return
            }
            _ = application.activate(options: [.activateAllWindows])
            if attempt < 2 {
                try await Task.sleep(nanoseconds: 350_000_000)
            }
        }
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier ==
                application.processIdentifier else {
            throw KakaoTalkError.activationFailed
        }
    }

    private func waitForLoginButton(in application: AXUIElement) async -> AXUIElement? {
        for attempt in 0..<4 {
            if let button = accessibility.loginButton(in: application) {
                return button
            }
            if attempt < 3 {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
        return nil
    }

    /// 사람이 Dock의 카카오톡 아이콘을 클릭하는 것과 같은 동작을 한다.
    /// 실행 중이 아니면 실행하고, 이미 실행 중이면 reopen 이벤트를 보내 창을 다시 띄운다.
    /// `NSRunningApplication.activate()`는 앱을 앞으로 가져올 뿐 창을 띄우지 않으므로
    /// 창이 내려가 있으면 로그인 화면을 찾지 못한다.
    private func openOrFindApplication(at url: URL) async throws -> NSRunningApplication {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        return try await NSWorkspace.shared.openApplication(
            at: url,
            configuration: configuration
        )
    }

    private func findInstalledApplication() -> URL? {
        for bundleIdentifier in knownBundleIdentifiers {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
               validate(applicationURL: url) {
                return normalized(url)
            }
        }

        let candidates = [
            URL(fileURLWithPath: "/Applications/KakaoTalk.app"),
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications/KakaoTalk.app")
        ]
        return candidates
            .first(where: { validate(applicationURL: $0) })
            .map { normalized($0) }
    }

    private func validate(applicationURL: URL) -> Bool {
        let url = normalized(applicationURL)
        guard url.pathExtension.lowercased() == "app",
              url.lastPathComponent.caseInsensitiveCompare("KakaoTalk.app") == .orderedSame,
              let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier?.lowercased(),
              bundleIdentifier.contains("kakao"),
              let executableURL = bundle.executableURL,
              fileManager.isExecutableFile(atPath: executableURL.path) else {
            return false
        }
        return true
    }

    private func validate(
        runningApplication: NSRunningApplication,
        expectedURL: URL
    ) -> Bool {
        guard let runningURL = runningApplication.bundleURL,
              normalized(runningURL) == normalized(expectedURL),
              let bundleIdentifier = runningApplication.bundleIdentifier?.lowercased(),
              bundleIdentifier.contains("kakao") else {
            return false
        }
        return validate(applicationURL: runningURL)
    }

    private func normalized(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }
}

enum LoginOutcome {
    case submitted
    case alreadyLoggedIn
    case loginWindowNotFound
    case passwordFieldNotFound
}

enum KakaoTalkError: LocalizedError {
    case notInstalled
    case processVerificationFailed
    case activationFailed
    case loginButtonNotFound

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "응용 프로그램 폴더에서 카카오톡을 찾지 못했습니다."
        case .processVerificationFailed:
            return "실행 중인 카카오톡 앱의 경로와 번들을 확인하지 못해 입력을 중단했습니다."
        case .activationFailed:
            return "카카오톡이 전면 앱인지 확인하지 못해 입력을 중단했습니다."
        case .loginButtonNotFound:
            return "카카오톡 로그인 버튼을 확인하지 못했습니다. 카카오톡 화면이 변경되었을 수 있습니다."
        }
    }
}
