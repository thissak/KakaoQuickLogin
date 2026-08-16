import SwiftUI

struct PasswordEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var passwordFocused: Bool
    @State private var password = ""

    let mode: PasswordPromptMode
    let onSave: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.title)
                        .font(.title2.weight(.semibold))
                    Text("비밀번호는 macOS 키체인에 암호화되어 저장됩니다.")
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .help("취소 (esc)")
                .accessibilityLabel("취소")
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
