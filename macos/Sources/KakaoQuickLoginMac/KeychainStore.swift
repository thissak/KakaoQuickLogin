import Foundation
import Security

actor KeychainStore {
    private let service = "dev.goldenlabs.KakaoQuickLogin"
    private let account = "kakaotalk-password-v1"

    func hasPassword() throws -> Bool {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            throw KeychainError.status(status)
        }
    }

    func loadPassword() throws -> Data? {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidStoredValue
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.status(status)
        }
    }

    func savePassword(_ password: String) throws {
        guard !password.isEmpty else {
            throw KeychainError.emptyPassword
        }

        var passwordData = Data(password.utf8)
        defer { passwordData.resetBytes(in: 0..<passwordData.count) }

        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]

        let updateStatus = SecItemUpdate(
            baseQuery() as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainError.status(updateStatus)
        }

        var addQuery = baseQuery()
        addQuery[kSecValueData as String] = passwordData

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.status(addStatus)
        }
    }

    func deletePassword() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.status(status)
        }
    }

    // 파일 기반 로그인 키체인을 사용한다. 데이터 보호 키체인은 접근 그룹 entitlement와
    // 그것을 승인하는 프로비저닝 프로파일을 앱에 임베드해야 하며(TN3137), 그 구성 없이
    // 접근하면 SecItemAdd가 -34018(errSecMissingEntitlement)로 실패한다.
    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum KeychainError: LocalizedError {
    case status(OSStatus)
    case emptyPassword
    case invalidStoredValue
    case invalidPasswordEncoding

    var errorDescription: String? {
        switch self {
        case .status(let status):
            let systemMessage = SecCopyErrorMessageString(status, nil) as String?
            return "macOS 키체인 작업을 완료하지 못했습니다. \(systemMessage ?? "오류 코드 \(status)")"
        case .emptyPassword:
            return "비밀번호를 입력해 주세요."
        case .invalidStoredValue, .invalidPasswordEncoding:
            return "키체인에 저장된 비밀번호 형식을 읽을 수 없습니다. 비밀번호를 다시 저장해 주세요."
        }
    }
}
