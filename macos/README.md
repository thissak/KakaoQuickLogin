# macOS 빌드 안내

macOS판은 SwiftUI, macOS 키체인, Accessibility API로 구성됩니다. Windows판과 마찬가지로
비밀번호를 외부로 전송하거나 평문 파일·클립보드에 저장하지 않습니다.

## 요구사항

- macOS 13 이상
- 호환되는 최신 Xcode
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- 응용 프로그램 폴더에 설치된 macOS용 카카오톡

```bash
brew install xcodegen
```

## Xcode 프로젝트 생성

```bash
cd macos
./scripts/generate-project.sh
open KakaoQuickLoginMac.xcodeproj
```

Xcode에서 `KakaoQuickLoginMac` 타깃을 선택하고 **Signing & Capabilities**에서 감독님의
Development Team을 선택한 뒤 실행하세요. 최초 실행 시 다음 권한이 필요합니다.

1. 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용
2. `카카오톡 빠른 로그인` 허용
3. 앱을 다시 실행

## 명령줄 컴파일 확인

```bash
./scripts/build.sh
```

이 명령은 서명하지 않은 Debug 앱을 컴파일해 소스와 프로젝트 설정을 확인합니다. 키체인과
손쉬운 사용을 포함한 실제 동작 시험은 Xcode에서 Development Team으로 서명한 앱으로 하세요.

## Developer ID 배포

Apple Developer Program 가입, `Developer ID Application` 인증서와 `notarytool` 프로필이
필요합니다. 먼저 자격 증명을 키체인에 저장합니다.

```bash
xcrun notarytool store-credentials KakaoQuickLogin-notary
```

그다음 서명·공증·스테이플·Gatekeeper 검증을 실행합니다.

```bash
./scripts/archive-and-notarize.sh \
  "TEAM_ID" \
  "Developer ID Application: 이름 (TEAM_ID)" \
  "KakaoQuickLogin-notary"
```

산출물은 저장소의 `artifacts/macos/`에 생성됩니다.

## 안전 동작

앱은 다음 조건을 모두 만족할 때만 비밀번호를 입력하고 로그인 버튼을 누릅니다.

- `KakaoTalk.app` 경로와 카카오 번들 식별자를 확인함
- 실행 프로세스의 앱 경로가 확인한 설치 경로와 같음
- 카카오톡이 전면 앱임
- Accessibility에서 `AXSecureTextField` 하위 역할을 확인함
- 접근성 제목이 `로그인`, `Login` 또는 `Log In`인 활성 버튼을 확인함

조건이 하나라도 맞지 않으면 입력을 중단합니다. 카카오톡 업데이트로 접근성 구조가 바뀌면
macOS판도 조정이 필요할 수 있습니다.
