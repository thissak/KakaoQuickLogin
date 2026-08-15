import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    private static let supportEmail = URL(string: "mailto:daeuk@goldenlabs.dev")
    private static let homepage = URL(string: "https://goldenlabs.dev")

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let shortVersion = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(shortVersion) (\(build))"
    }

    var body: some View {
        Form {
            Section("저장된 로그인 정보") {
                Button("비밀번호 변경", action: model.requestPasswordReset)
                Button("저장된 비밀번호 삭제", role: .destructive, action: model.forgetPassword)
            }

            Section("권한") {
                Button("손쉬운 사용 설정 열기", action: model.openAccessibilitySettings)
                Text("카카오톡 로그인 화면을 확인하고 조작하려면 손쉬운 사용 권한이 필요합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("정보") {
                LabeledContent("버전", value: versionText)
                LabeledContent("만든 곳", value: "골든랩 (GoldenLabs)")
                if let supportEmail = Self.supportEmail {
                    Link("daeuk@goldenlabs.dev", destination: supportEmail)
                }
                if let homepage = Self.homepage {
                    Link("goldenlabs.dev", destination: homepage)
                }
                Text("카카오 또는 카카오톡의 공식 제품이 아니며, 카카오와 제휴하거나 카카오가 보증하는 프로그램이 아닙니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 460, height: 430)
    }
}
