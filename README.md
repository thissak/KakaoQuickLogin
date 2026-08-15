# KakaoQuickLogin

Windows와 macOS용 카카오톡 빠른 로그인 도구입니다. 최초 한 번 저장한 비밀번호를 이용해
카카오톡 로그인 화면을 확인한 뒤 비밀번호를 입력하고 로그인을 실행합니다.

> 카카오 또는 카카오톡의 공식 제품이 아니며, 카카오와 제휴하거나 카카오가 보증하는
> 프로그램이 아닙니다.

## 지원 환경

- Windows 10/11 x64와 Windows용 카카오톡
- macOS 13 이상과 macOS용 카카오톡
- 카카오톡 계정이 선택되어 있고 비밀번호 입력 화면이 표시되는 상태

Windows와 macOS는 운영체제 보안 저장소와 자동화 API가 달라 별도 네이티브 앱으로
구현합니다. 사용자 흐름은 동일합니다.

## 보안 원칙

- 비밀번호를 서버로 전송하지 않습니다.
- 비밀번호를 클립보드나 평문 설정 파일에 저장하지 않습니다.
- Windows에서는 DPAPI `CurrentUser`, macOS에서는 데이터 보호 키체인에 저장합니다.
- 실행 중에도 카카오톡 설치 경로, 프로세스, 로그인 창과 비밀번호 입력란을 확인한 뒤에만 입력합니다.

자세한 내용은 [SECURITY.md](SECURITY.md)를 참고하세요.

## Windows 사용법

1. 릴리스 ZIP을 원하는 폴더에 풉니다.
2. `KakaoQuickLogin.exe`를 실행합니다.
3. 최초 한 번 카카오톡 비밀번호를 입력하고 **저장**을 누릅니다.
4. 이후에는 `KakaoQuickLogin.exe`만 실행합니다.

비밀번호를 변경하려면 **Shift 키를 누른 상태로 EXE를 실행**합니다. 명령줄에서는
`KakaoQuickLogin.exe --reset`을 사용할 수 있습니다.

저장된 비밀번호를 삭제하려면 `KakaoQuickLogin.exe --forget`을 실행합니다.

## macOS 설치

Homebrew로 설치합니다.

```bash
brew tap thissak/tap
brew install --cask kakao-quick-login
```

또는 [릴리스 페이지](https://github.com/thissak/KakaoQuickLogin/releases)에서 ZIP을 받아
`KakaoQuickLogin.app`을 `/응용 프로그램`으로 옮깁니다. Developer ID로 서명하고 Apple
공증을 받은 빌드라 Gatekeeper 경고 없이 실행됩니다.

## macOS 사용법

1. 앱을 실행하고 최초 한 번 카카오톡 비밀번호를 입력해 저장합니다.
2. macOS가 요청하는 손쉬운 사용 권한을 허용합니다.
3. 이후에는 앱을 실행하기만 하면 저장된 비밀번호로 로그인합니다.

비밀번호 변경과 삭제는 앱의 설정 화면에서 할 수 있습니다.

### 소스에서 빌드

```bash
cd macos
brew install xcodegen
./scripts/generate-project.sh
open KakaoQuickLoginMac.xcodeproj
```

Xcode의 **Signing & Capabilities**에서 Development Team을 선택해야 합니다.

상세 빌드와 Developer ID 배포 절차는 [macos/README.md](macos/README.md)를 참고하세요.

## 동작 범위

카카오톡 화면 구조가 변경되면 새 버전이 필요할 수 있습니다. 이 프로그램은 계정 인증을
우회하지 않으며, 추가 인증이나 보안 확인이 표시되면 사용자가 직접 완료해야 합니다.

## Windows 빌드

```powershell
.\scripts\bootstrap-dotnet.ps1
.\scripts\build.ps1
```

산출물은 `artifacts\KakaoQuickLogin-<version>-win-x64.zip`에 생성됩니다.

전체 공개 배포 절차와 점검표는 [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md)를 참고하세요.

## 만든 곳

골든랩 (GoldenLabs) — [goldenlabs.dev](https://goldenlabs.dev)

버그 제보와 문의는 [이슈](https://github.com/thissak/KakaoQuickLogin/issues) 또는
daeuk@goldenlabs.dev 로 보내주세요.
