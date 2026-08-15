---
lifecycle: active
last_updated: 2026-08-13
---

# 진행 현황

## 목표

Windows와 macOS에서 카카오톡 비밀번호를 운영체제 보안 저장소에 한 번 저장하고, 이후 앱
실행 한 번으로 카카오톡 비밀번호 로그인 화면에 안전하게 입력하는 배포용 프로그램을 만듭니다.

## 완료

- Windows x64 .NET 네이티브 UI, DPAPI 저장, UI Automation 로그인, 단일 EXE 패키징
- macOS SwiftUI UI, 데이터 보호 키체인 저장, Accessibility 기반 로그인
- 확인된 카카오톡 프로세스와 포커스된 보안 입력란에만 자동 입력하는 실패 차단 로직
- Windows 빌드·자체 테스트와 macOS XcodeGen·빌드·Developer ID 공증 스크립트
- Windows와 macOS를 검사하는 GitHub Actions 워크플로

## 현재 검증 상태

- Windows Release 빌드, 단일 EXE 게시, DPAPI 자체 테스트: 통과
- macOS 프로젝트 YAML·Swift 구문 정적 검사와 GitHub Actions Xcode 컴파일: 통과
- macOS 키체인·손쉬운 사용 권한과 최신 카카오톡 연동: **실제 Mac에서 통과**(2026-08-14).
  카카오톡이 비전면인 상태에서 앱 실행 → 비밀번호 자동 입력 → 로그인 버튼 클릭 → 메인 창
  전환까지 약 1초에 완료. 검증 방법과 로그는
  [handoff](handoff/2026-08-13-macos-signing-notarization.md) 참고.
- macOS Developer ID 서명과 Apple 공증: 통과 (`spctl` → `Notarized Developer ID`)

## 다음 작업

1. 비밀번호 변경·삭제와 특수문자·한글 비밀번호를 실제 Mac에서 시험합니다.
2. 카카오톡이 이미 로그인된 상태에서 `이미 로그인됨` 판정이 맞는지 확인합니다
   (현재 판정 규칙은 "제목이 `로그인`인 창이 없으면 로그인된 것으로 간주"이며 미검증).
3. 번들 ID를 바꿨으므로 새 번들 ID로 서명·공증본을 다시 만들고, 손쉬운 사용 권한을
   다시 승인한 뒤 로그인 동작을 재확인합니다.
4. `thissak/homebrew-tap` 저장소를 만들고 캐스크의 `sha256`을 새 공증본 값으로 채웁니다.
5. GitHub 릴리스 `v0.1.0`을 발행하고 저장소 About·토픽을 설정합니다.
6. 공개 배포 시 `docs/DISTRIBUTION.md` 점검표를 수행합니다.
