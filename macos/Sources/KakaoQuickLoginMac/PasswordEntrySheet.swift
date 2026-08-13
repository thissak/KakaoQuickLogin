import SwiftUI

struct PasswordEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var passwordFocused: Bool
    @State private var password = ""

    let mode: PasswordPromptMode
    let onSave: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(mode.title)
                    .font(.title2.weight(.semibold))
                Text("비밀번호는 macOS 키체인에 암호화되어 저장됩니다.")
                    .foregroundStyle(.secondary)
            }

            Form {
                SecureField("카카오톡 비밀번호", text: $password)
                    .focused($passwordFocused)
                    .onSubmit(save)
                    .accessibilityHint("카카오톡 계정의 비밀번호를 입력합니다.")
            }
            .formStyle(.grouped)
            .frame(height: 90)

            HStack {
                if mode == .reset {
                    Button("취소", role: .cancel) { dismiss() }
                }

                Spacer()

                Button("키체인에 저장", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(password.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear { passwordFocused = true }
        .onDisappear { password.removeAll(keepingCapacity: false) }
    }

    private func save() {
        guard !password.isEmpty else { return }
        let submittedPassword = password
        password.removeAll(keepingCapacity: false)
        onSave(submittedPassword)
    }
}
