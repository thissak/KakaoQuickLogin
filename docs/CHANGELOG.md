# 변경 기록

### 2026-08-16

- [fix] 모든 단계에서 esc 또는 X 버튼으로 취소할 수 있게 했습니다. 최초 설정의 비밀번호
  저장 시트는 취소 버튼이 `.reset` 모드에만 있었고 `interactiveDismissDisabled`로 esc까지
  막혀 있어, 처음 실행한 사용자가 앱을 종료하는 것 말고는 시트를 닫을 방법이 없었습니다.
  시트 오른쪽 위에 X 버튼을 두고 두 모드 모두 esc로 닫히게 했습니다.
- [fix] 진행 중인 로그인·저장 작업을 취소할 수 있게 했습니다. 카카오톡 로그인 창을 기다리는
  구간이 최대 20초인데 그동안 모든 버튼이 비활성이라 멈출 수단이 없었습니다. `AppModel`이
  실행 중인 `Task`를 들고 있다가 취소하고, 자동화의 대기 루프는 `Task.checkCancellation()`과
  취소를 던지는 `Task.sleep`으로 바꿔 즉시 빠져나옵니다. 취소하면 상태 카드가 "취소됨"으로
  바뀌고 다시 시도할 수 있습니다.
- [build] 버전을 `0.1.1`로 올려 서명·공증했습니다
  (`KakaoQuickLogin-0.1.1-macos-universal.zip`, SHA-256 `91a9ff98…`,
  `spctl` → `Notarized Developer ID`). `0.1.0`은 이미 GitHub 릴리스와 Homebrew 탭에
  `01a9cc09…`로 고정 배포된 상태라 같은 번호로 다시 말면 해시가 어긋납니다. Cask의
  `version`·`sha256`도 새 값으로 갱신했습니다.
- [build] `archive-and-notarize.sh`가 배포 ZIP 이름의 버전을 `Info.plist`에서 읽습니다.
  하드코딩된 `0.1.0`을 그대로 두면 버전을 올린 뒤에도 옛 이름으로 덮어써
  이미 배포된 파일과 충돌합니다.
- [build] 릴리스에 함께 올리는 `.sha256` 파일에 빌드한 Mac의 절대 경로가 남지 않게 했습니다.
  `shasum`은 인자로 준 경로를 그대로 출력하므로 절대 경로로 호출하면 사용자 계정명이
  공개 자산에 노출됩니다. 이미 올라간 v0.1.1 자산도 파일 이름만 담은 것으로 교체했습니다.
- [chore] `v0.1.1`을 공개 배포했습니다. GitHub 릴리스에 ZIP·SHA-256을 올리고
  `thissak/homebrew-tap`의 캐스크를 갱신했습니다. `brew style`·`brew audit --online`
  무결점, `brew upgrade --cask`로 0.1.0 → 0.1.1 실제 업그레이드와 설치본의 `spctl`·
  `stapler validate`까지 확인했습니다. 번들 ID가 같아 키체인 항목과 손쉬운 사용 권한은
  유지됩니다.

### 2026-08-15

- [feat] macOS 앱 아이콘을 추가했습니다 (그래파이트 배경·흰 말풍선·골드 번개). 그동안
  애셋 카탈로그가 없어 Dock에 기본 플레이스홀더가 떴습니다. 카카오 브랜드 색과 로고를
  쓰지 않은 것은 상표 분쟁 소지를 남기면 Homebrew 배포와 공개 배포가 함께 막히기
  때문입니다. 16~1024px을 각 크기에서 네이티브 렌더링해 작은 크기의 뭉개짐을 줄였습니다.
- [feat] 앱 설정 화면에 정보 섹션(버전·만든 곳·연락처·비제휴 고지)을 넣었습니다.
- [breaking] 번들 ID를 `io.github.thissak.KakaoQuickLogin`에서
  `dev.goldenlabs.KakaoQuickLogin`으로 바꾸고 키체인 service 이름도 맞췄습니다. 공개 배포
  전이 마지막 변경 시점이라 지금 바꿨습니다. 배포 후에 바꾸면 사용자의 손쉬운 사용 권한
  승인과 키체인 항목이 모두 초기화됩니다. 옛 빌드를 쓰던 Mac은 비밀번호를 한 번 다시
  입력해야 합니다.
- [feat] Homebrew Cask 정의를 `packaging/homebrew/kakao-quick-login.rb`에 추가했습니다.
  공식 `homebrew/cask`는 notability를 정성 심사해 갓 공개된 소프트웨어를 받지 않으므로,
  개인 탭(`thissak/homebrew-tap`)으로 먼저 배포합니다. 개인 탭에는 요건이 없습니다.
- [docs] `docs/DISTRIBUTION.md`에 Homebrew 배포 절차, 저장소 메타데이터 노출 항목, 번들 ID
  변경 이력을 추가하고 README에 설치·연락처 안내를 넣었습니다.
- [docs] 설치 안내에 `brew trust` 단계를 넣었습니다. Homebrew는 공식 저장소 밖의 탭을
  불러오기 전에 trust 확인을 요구하며, 이 단계를 빼면 `Refusing to load cask ... from
  untrusted tap`으로 설치가 중단됩니다. `~/.homebrew/trust.json`을 비우고 실제 첫 설치
  경로를 재현해 확인했습니다.
- [build] 새 번들 ID와 아이콘으로 유니버설 빌드를 다시 서명·공증했습니다
  (`KakaoQuickLogin-0.1.0-macos-universal.zip`, SHA-256 `01a9cc09…`,
  `spctl` → `Notarized Developer ID`).

### 2026-08-14

- [fix] macOS 비밀번호 저장을 파일 기반 로그인 키체인으로 바꿨습니다. 데이터 보호 키체인은
  접근 그룹 entitlement와 이를 승인하는 프로비저닝 프로파일을 앱에 임베드해야 해서
  (Apple TN3137), 구성이 없는 상태로는 저장이 `-34018`로 실패했습니다. 근거와 대안 검토는
  [ADR 002](adr/002-macos-file-based-keychain.md)에 남겼습니다.
- [fix] macOS 로그인 버튼 판정을 공백 제거 후 정확 일치로 좁혔습니다. 부분 일치를 쓰면
  카카오톡 로그인 창의 `  QR코드 로그인` 버튼이 함께 걸려, 비밀번호가 비어 진짜 로그인
  버튼이 비활성인 시점에 QR 버튼이 눌리는 것을 막기 위함입니다.
- [fix] macOS에서 로그인 버튼을 비밀번호 입력 뒤에 찾도록 순서를 바꿨습니다. 카카오톡은
  비밀번호가 채워져야 로그인 버튼을 활성화하므로, 입력 전에 확정하면 잘못된 버튼을
  잡습니다.
- [fix] macOS에서 카카오톡을 `NSWorkspace.openApplication`으로 엽니다. 사람이 Dock
  아이콘을 클릭하는 것과 같은 reopen 경로여서, 창이 내려가 있어도 로그인 창이 다시
  뜹니다. `NSRunningApplication.activate`는 앱을 앞으로 가져올 뿐 창을 띄우지 않습니다.
- [feat] macOS 로그인 결과를 `이미 로그인됨`·`로그인 창 없음`·`입력란 없음`으로 구분해
  안내합니다. 이미 로그인된 정상 상태에 실패 경고가 뜨던 것을 고치기 위함이며, Windows판의
  `AlreadyLoggedIn`·`LoginWindowNotFound`·`PasswordFieldNotFound` 구분과 맞췄습니다.
- [fix] macOS에서 카카오톡 로그인 창을 기다리는 시간을 1.6초에서 20초로 늘렸습니다.
  Windows판이 프로세스와 창 등장에 각각 20초를 쓰는 것과 맞춰, 카카오톡이 막 실행되었을 때
  놓치지 않기 위함입니다.
- [build] macOS 배포본을 실제 동작 검증 후 다시 공증했습니다
  (`KakaoQuickLogin-0.1.0-macos-universal.zip`, SHA-256 `b3ae0c6c…`).

### 2026-08-13

- [chore] GOLEM 카탈로그에 등록되었습니다 (id `kakao-quick-login`, org `personal`). 프로젝트
  위치를 상위 Control Plane에서 집계하기 위함이며, 상태 SSOT는 이 저장소의 문서에 그대로
  남습니다.
- [docs] GitHub Actions의 macOS Xcode 빌드 통과 결과를 진행·인계 문서에 반영했습니다.
  Mac에서 남은 실제 카카오톡 연동 검증 범위를 정확히 전달하기 위함입니다.
- [build] macOS 배포본을 Developer ID로 서명하고 Apple 공증을 완료했습니다
  (`KakaoQuickLogin-0.1.0-macos-universal.zip`, 유니버설, `spctl` → `Notarized Developer ID`).
  다른 Mac에서 Gatekeeper 경고 없이 실행되게 하기 위함입니다. 상세는
  `docs/handoff/2026-08-13-macos-signing-notarization.md`를 참고하세요.
- [fix] macOS `project.yml`에서 Info.plist·entitlements 생성 키를 제거했습니다. XcodeGen이
  빌드마다 저장소의 Info.plist를 기본 템플릿으로 덮어써 한글 표시 이름·버전 `0.1.0`·최소
  시스템 버전·`NSPrincipalClass`가 사라지는 것을 막기 위함입니다. 두 파일은 이미
  `INFOPLIST_FILE`·`CODE_SIGN_ENTITLEMENTS` 설정으로 연결되어 있습니다.
- [fix] macOS 상태 UI의 계산 속성에 명시적 반환을 추가했습니다. Swift 5 모드의 Xcode
  컴파일 오류를 해결하기 위함입니다.
- [feat] Windows x64 휴대형 단일 EXE와 DPAPI 기반 비밀번호 저장을 추가했습니다. 설치 없이
  실행하고 현재 Windows 사용자 범위에서 비밀번호를 보호하기 위함입니다.
- [feat] SwiftUI, macOS 키체인, Accessibility API를 사용한 macOS 앱을 추가했습니다. 두
  플랫폼에서 동일한 빠른 로그인 흐름을 제공하되 각 운영체제의 네이티브 보안 기능을
  사용하기 위함입니다.
- [security] 카카오톡 앱·프로세스·전면 상태·보안 입력란·로그인 버튼 검증을 추가했습니다.
  확인되지 않은 화면에 비밀번호가 입력되는 것을 막기 위함입니다.
- [build] Windows 패키징과 macOS 프로젝트 생성·유니버설 아카이브·서명·공증 스크립트,
  GitHub Actions 빌드를 추가했습니다. 플랫폼별 빌드와 배포를 재현 가능하게 만들기 위함입니다.
