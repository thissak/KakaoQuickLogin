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

        guard runningApplication.activate(options: [.activateAllWindows]) else {
            throw KakaoTalkError.activationFailed
        }
        try await Task.sleep(nanoseconds: 350_000_000)

        guard NSWorkspace.shared.frontmostApplication?.processIdentifier ==
                runningApplication.processIdentifier else {
            throw KakaoTalkError.activationFailed
        }

        let applicationElement = AXUIElementCreateApplication(runningApplication.processIdentifier)
        AXUIElementSetMessagingTimeout(applicationElement, 4)

        guard let passwordField = await waitForPasswordField(in: applicationElement) else {
            return .notOnPasswordScreen
        }
        guard let loginButton = accessibility.loginButton(in: applicationElement) else {
            throw KakaoTalkError.loginButtonNotFound
        }

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

        try accessibility.press(loginButton)
        return .submitted
    }

    func openAccessibilitySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    private func waitForPasswordField(in application: AXUIElement) async -> AXUIElement? {
        for attempt in 0..<4 {
            if let field = accessibility.securePasswordField(in: application) {
                return field
            }
            if attempt < 3 {
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
        return nil
    }

    private func openOrFindApplication(at url: URL) async throws -> NSRunningApplication {
        if let bundleIdentifier = Bundle(url: url)?.bundleIdentifier,
           let runningApplication = NSRunningApplication
               .runningApplications(withBundleIdentifier: bundleIdentifier)
               .first(where: { candidate in
                   guard let candidateURL = candidate.bundleURL else { return false }
                   return normalized(candidateURL) == normalized(url)
               }) {
            return runningApplication
        }

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
    case notOnPasswordScreen
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
