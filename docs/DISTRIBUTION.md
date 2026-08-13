# 배포 안내

## Windows

### 1. 릴리스 빌드

```powershell
.\scripts\bootstrap-dotnet.ps1
.\scripts\build.ps1
```

`artifacts` 폴더에 휴대형 ZIP과 SHA-256 파일이 생성됩니다. 빌드 과정에서 DPAPI 자체
테스트가 실패하면 패키지를 만들지 않습니다.

### 2. 공개 배포용 코드 서명

서명되지 않은 EXE에는 Windows SmartScreen 경고가 나타날 수 있습니다. 공개 배포 전에는
신뢰된 코드 서명 인증서를 준비하고 Windows SDK의 `SignTool.exe`가 설치된 PC에서 빌드합니다.

```powershell
.\scripts\build.ps1 -CertificateThumbprint '<인증서 지문>'
```

자가 서명 인증서는 공개 배포용으로 사용하지 않습니다.

### 3. Windows 수동 확인

- 깨끗한 Windows 10/11 x64 사용자 계정에서 최초 실행
- 올바른 비밀번호와 특수문자 포함 비밀번호 입력
- 로그인 화면이 아닐 때 다른 창에 입력하지 않는지
- `--reset`, `--forget` 동작
- 최신 카카오톡의 로그인 화면 탐지
- 서명 상태와 게시한 SHA-256 값

## macOS

### 1. 개발 빌드

Mac에서 다음 명령으로 Xcode 프로젝트와 Debug 앱을 만듭니다.

```bash
brew install xcodegen
./macos/scripts/build.sh
```

실제 키체인·손쉬운 사용 시험은 `macos/README.md`의 안내대로 Xcode에서 Development Team을
선택해 서명한 앱으로 수행합니다.

### 2. 공개 배포용 서명과 공증

Apple Developer Program, `Developer ID Application` 인증서, `notarytool` 프로필이 필요합니다.

```bash
xcrun notarytool store-credentials KakaoQuickLogin-notary
./macos/scripts/archive-and-notarize.sh \
  "TEAM_ID" \
  "Developer ID Application: 이름 (TEAM_ID)" \
  "KakaoQuickLogin-notary"
```

스크립트는 Intel·Apple Silicon 유니버설 앱을 아카이브하고 서명 검증, 공증, 스테이플,
Gatekeeper 검증을 수행한 뒤 `artifacts/macos`에 ZIP과 SHA-256 파일을 만듭니다.

### 3. macOS 수동 확인

- Intel 또는 Rosetta 검사와 Apple Silicon 네이티브 실행
- 최초 키체인 저장, 변경, 삭제
- 손쉬운 사용 권한 미허용·허용 후의 안내와 재시도
- 특수문자와 한글이 포함된 비밀번호 입력
- 로그인 화면이 아닐 때 입력을 중단하는지
- 최신 카카오톡에서 보안 입력란과 로그인 버튼 탐지
- `codesign`, `notarytool`, `stapler`, `spctl` 검증 결과

## 공통 배포 고지

릴리스 페이지에는 다음 내용을 명시합니다.

- 카카오 또는 카카오톡의 공식 제품이 아니며 제휴 관계가 없다는 점
- 비밀번호는 해당 사용자 계정의 운영체제 보안 저장소에만 저장된다는 점
- 카카오톡 업데이트로 동작이 중단될 수 있다는 점
- 추가 인증이나 계정 보안 정책을 우회하지 않는다는 점
