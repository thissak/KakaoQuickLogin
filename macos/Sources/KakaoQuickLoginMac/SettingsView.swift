import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

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
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 460, height: 250)
    }
}
