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

## Homebrew 배포

### 1. 왜 개인 탭인가

공식 `homebrew/cask`는 **notability**(얼마나 널리 쓰이는지)를 심사합니다. 공개된 고정
수치 기준은 없고 정성 평가이며, 갓 공개된 소프트웨어는 "독립적으로 확인 가능한 공개
관심과 복수의 등록 요청"이 있어야 검토 대상이 된다고만 밝히고 있습니다
([Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)).

신규 저장소가 곧바로 통과하기는 어려우므로 개인 탭으로 먼저 배포하고, 사용 실적이
쌓인 뒤 공식 탭에 제출합니다. 개인 탭에는 어떤 요건도 없습니다.

### 2. 탭 저장소 만들기

`thissak/homebrew-tap` 저장소를 만들면 사용자는 `thissak/tap`으로 탭할 수 있습니다.

```bash
gh repo create thissak/homebrew-tap --public \
  --description "Homebrew tap for GoldenLabs macOS apps"
```

`Casks/kakao-quick-login.rb` 경로에 [packaging/homebrew/kakao-quick-login.rb](../packaging/homebrew/kakao-quick-login.rb)를
복사합니다.

### 3. 릴리스마다 갱신

공증 스크립트가 만든 ZIP의 SHA-256으로 `version`과 `sha256`을 갱신합니다.

```bash
shasum -a 256 artifacts/macos/KakaoQuickLogin-<version>-macos-universal.zip
```

탭 저장소에서 검증합니다.

```bash
brew style --cask thissak/tap/kakao-quick-login
brew audit --cask --online thissak/tap/kakao-quick-login
brew install --cask kakao-quick-login
```

`brew style`은 탭 안에 있는 캐스크만 검사합니다. 저장소 밖 파일을 지정하면
`Homebrew requires casks to be in a tap`으로 거절됩니다.

### 4. tap trust

Homebrew는 공식 저장소 밖의 탭을 불러오기 전에 **trust 확인**을 요구합니다. 사용자가
`brew trust`를 실행하지 않으면 설치가 다음과 같이 중단됩니다.

```
Error: Refusing to load cask thissak/tap/kakao-quick-login from untrusted tap thissak/tap.
```

따라서 안내하는 설치 명령은 반드시 세 줄이어야 합니다.

```bash
brew tap thissak/tap
brew trust --cask thissak/tap/kakao-quick-login
brew install --cask kakao-quick-login
```

Homebrew는 탭 전체(`brew trust thissak/tap`)보다 캐스크 단위 신뢰를 권장합니다. 신뢰
기록은 `~/.homebrew/trust.json`에 남으므로, 재현 시험을 할 때는 이 파일을 비워야 실제
첫 설치 경로가 나옵니다.

### 5. 검색 노출

릴리스와 저장소 메타데이터가 검색·자동화 도구의 유일한 입력입니다.

- 저장소 About에 한 줄 설명과 `goldenlabs.dev` 링크
- 토픽: `macos`, `swift`, `swiftui`, `kakaotalk`, `automation`, `accessibility`, `homebrew-cask`
- 릴리스 태그는 `v<semver>` 고정, 본문에 설치 명령과 SHA-256 명시

## 번들 ID 변경 이력

`0.1.0` 공개 배포부터 번들 ID를 `io.github.thissak.KakaoQuickLogin`에서
`dev.goldenlabs.KakaoQuickLogin`으로 바꿨습니다. 키체인 service 이름도 같은 값을 씁니다
(`macos/Sources/KakaoQuickLoginMac/KeychainStore.swift`).

옛 번들 ID로 빌드한 앱을 쓰던 Mac에서는 **저장된 비밀번호를 한 번 다시 입력**해야 합니다.
옛 키체인 항목은 자동으로 지워지지 않으므로 키체인 접근에서
`io.github.thissak.KakaoQuickLogin` 항목을 직접 삭제합니다.

공개 배포 이후에는 번들 ID를 다시 바꾸지 않습니다. 사용자의 손쉬운 사용 권한 승인과
키체인 항목이 모두 초기화됩니다.

## 공통 배포 고지

릴리스 페이지에는 다음 내용을 명시합니다.

- 카카오 또는 카카오톡의 공식 제품이 아니며 제휴 관계가 없다는 점
- 비밀번호는 해당 사용자 계정의 운영체제 보안 저장소에만 저장된다는 점
- 카카오톡 업데이트로 동작이 중단될 수 있다는 점
- 추가 인증이나 계정 보안 정책을 우회하지 않는다는 점
