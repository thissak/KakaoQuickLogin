import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.78))
                    .frame(width: 72, height: 72)
                    .background(Color.yellow, in: Circle())
                    .accessibilityHidden(true)

                Text("카카오톡 빠른 로그인")
                    .font(.title2.weight(.semibold))

                Text("비밀번호는 이 Mac의 키체인에만 저장됩니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            StatusCard(status: model.status, isBusy: model.isBusy)

            HStack(spacing: 10) {
                Button(action: model.login) {
                    HStack(spacing: 8) {
                        if model.isBusy {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text(model.isBusy ? "확인 중…" : "카카오톡 로그인")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .disabled(model.isBusy)
                .accessibilityHint("카카오톡 로그인 화면을 확인한 뒤 저장된 비밀번호로 로그인합니다.")

                if model.isBusy {
                    Button(action: model.cancelCurrentOperation) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                    .help("취소 (esc)")
                    .accessibilityLabel("취소")
                }
            }

            HStack(spacing: 12) {
                Button("비밀번호 변경", action: model.requestPasswordReset)
                    .disabled(model.isBusy)

                Button("손쉬운 사용 설정") {
                    model.openAccessibilitySettings()
                }
                .disabled(model.isBusy)
            }

            Text("카카오의 공식 제품이 아니며 추가 인증이나 보안 확인을 우회하지 않습니다.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(width: 440)
        .task { model.start() }
        .sheet(item: $model.passwordPrompt) { mode in
            PasswordEntrySheet(mode: mode) { password in
                model.savePassword(password, mode: mode)
            }
        }
    }
}
private struct StatusCard: View {
    let status: AppStatus
    let isBusy: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(status.title)
                    .font(.headline)
                Text(status.message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.title). \(status.message)")
    }

    private var symbolName: String {
        if isBusy { return "hourglass" }

        switch status.tone {
        case .ready: return "lock.shield"
        case .working: return "hourglass"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    private var tint: Color {
        switch status.tone {
        case .ready: return .accentColor
        case .working: return .accentColor
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}
