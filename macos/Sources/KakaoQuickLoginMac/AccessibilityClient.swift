import ApplicationServices
import Foundation

struct AccessibilityClient {
    private let maximumDepth = 12
    private let maximumElements = 1_500

    func requestTrustIfNeeded() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func securePasswordField(in application: AXUIElement) -> AXUIElement? {
        firstDescendant(in: application) { element in
            stringAttribute(element, kAXRoleAttribute) == kAXTextFieldRole &&
                stringAttribute(element, kAXSubroleAttribute) == kAXSecureTextFieldSubrole &&
                boolAttribute(element, kAXEnabledAttribute, defaultValue: true)
        }
    }

    func loginButton(in application: AXUIElement) -> AXUIElement? {
        firstDescendant(in: application) { element in
            guard stringAttribute(element, kAXRoleAttribute) == kAXButtonRole,
                  boolAttribute(element, kAXEnabledAttribute, defaultValue: true) else {
                return false
            }

            let labels = [
                stringAttribute(element, kAXTitleAttribute),
                stringAttribute(element, kAXDescriptionAttribute),
                stringAttribute(element, kAXHelpAttribute),
                stringAttribute(element, kAXIdentifierAttribute)
            ]
            .compactMap { $0?.lowercased() }

            return labels.contains { label in
                label == "로그인" || label == "login" || label == "log in" ||
                    label.contains("로그인")
            }
        }
    }

    func focusAndVerify(
        _ passwordField: AXUIElement,
        in application: AXUIElement
    ) throws {
        let focusResult = AXUIElementSetAttributeValue(
            passwordField,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
        guard focusResult == .success else {
            throw AccessibilityError.cannotFocusPasswordField(focusResult)
        }

        guard let focusedElement = elementAttribute(application, kAXFocusedUIElementAttribute),
              CFEqual(focusedElement, passwordField) else {
            throw AccessibilityError.focusVerificationFailed
        }
    }

    func setPasswordValueIfAvailable(
        _ password: String,
        in passwordField: AXUIElement
    ) -> Bool {
        var settable = DarwinBoolean(false)
        let settableResult = AXUIElementIsAttributeSettable(
            passwordField,
            kAXValueAttribute as CFString,
            &settable
        )
        guard settableResult == .success, settable.boolValue else {
            return false
        }

        let valueResult = AXUIElementSetAttributeValue(
            passwordField,
            kAXValueAttribute as CFString,
            password as CFString
        )
        return valueResult == .success
    }

    func press(_ button: AXUIElement) throws {
        let result = AXUIElementPerformAction(button, kAXPressAction as CFString)
        guard result == .success else {
            throw AccessibilityError.cannotPressLoginButton(result)
        }
    }

    private func firstDescendant(
        in root: AXUIElement,
        matching predicate: (AXUIElement) -> Bool
    ) -> AXUIElement? {
        var queue: [(element: AXUIElement, depth: Int)] = [(root, 0)]
        var index = 0

        while index < queue.count, index < maximumElements {
            let current = queue[index]
            index += 1

            if current.depth > 0, predicate(current.element) {
                return current.element
            }

            guard current.depth < maximumDepth else { continue }
            for child in children(of: current.element) {
                queue.append((child, current.depth + 1))
                if queue.count >= maximumElements { break }
            }
        }

        return nil
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &value
        )
        guard result == .success else { return [] }
        return value as? [AXUIElement] ?? []
    }

    private func elementAttribute(
        _ element: AXUIElement,
        _ attribute: String
    ) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private func stringAttribute(
        _ element: AXUIElement,
        _ attribute: String
    ) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value as? String
    }

    private func boolAttribute(
        _ element: AXUIElement,
        _ attribute: String,
        defaultValue: Bool
    ) -> Bool {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return defaultValue }
        return value as? Bool ?? defaultValue
    }
}

enum AccessibilityError: LocalizedError {
    case permissionRequired
    case cannotFocusPasswordField(AXError)
    case focusVerificationFailed
    case cannotPressLoginButton(AXError)

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return "시스템 설정의 개인정보 보호 및 보안 > 손쉬운 사용에서 이 앱을 허용한 뒤 다시 실행해 주세요."
        case .cannotFocusPasswordField, .focusVerificationFailed:
            return "카카오톡 비밀번호 입력란의 포커스를 확인하지 못해 입력을 중단했습니다."
        case .cannotPressLoginButton:
            return "카카오톡 로그인 버튼을 안전하게 누르지 못했습니다."
        }
    }
}
