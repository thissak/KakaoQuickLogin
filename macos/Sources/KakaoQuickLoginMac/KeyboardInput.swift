import CoreGraphics
import Foundation

struct KeyboardInput {
    func replaceFocusedText(_ text: String, in processIdentifier: pid_t) throws {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            throw KeyboardInputError.cannotCreateEventSource
        }

        try postCommandA(source: source, processIdentifier: processIdentifier)

        var codeUnits = Array(text.utf16)
        defer {
            for index in codeUnits.indices {
                codeUnits[index] = 0
            }
        }

        guard let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: 0,
            keyDown: true
        ), let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: 0,
            keyDown: false
        ) else {
            throw KeyboardInputError.cannotCreateKeyboardEvent
        }

        codeUnits.withUnsafeBufferPointer { buffer in
            keyDown.keyboardSetUnicodeString(
                stringLength: buffer.count,
                unicodeString: buffer.baseAddress
            )
            keyUp.keyboardSetUnicodeString(
                stringLength: buffer.count,
                unicodeString: buffer.baseAddress
            )
        }

        keyDown.postToPid(processIdentifier)
        keyUp.postToPid(processIdentifier)
    }

    private func postCommandA(
        source: CGEventSource,
        processIdentifier: pid_t
    ) throws {
        let aKeyCode: CGKeyCode = 0
        guard let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: aKeyCode,
            keyDown: true
        ), let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: aKeyCode,
            keyDown: false
        ) else {
            throw KeyboardInputError.cannotCreateKeyboardEvent
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.postToPid(processIdentifier)
        keyUp.postToPid(processIdentifier)
    }
}

enum KeyboardInputError: LocalizedError {
    case cannotCreateEventSource
    case cannotCreateKeyboardEvent

    var errorDescription: String? {
        "카카오톡 비밀번호 입력 이벤트를 만들지 못해 입력을 중단했습니다."
    }
}
