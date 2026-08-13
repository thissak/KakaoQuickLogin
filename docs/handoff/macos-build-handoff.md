# macOS 빌드 인계

## 준비된 내용

- SwiftUI 앱과 최초 저장·로그인·비밀번호 변경·삭제 화면
- 데이터 보호 키체인 기반 비밀번호 저장
- 카카오톡 번들·실행 경로·전면 앱·보안 입력란·로그인 버튼 확인
- 접근성 값 설정과 대상 프로세스 전용 키보드 이벤트 입력
- XcodeGen 프로젝트, Debug 컴파일, 유니버설 아카이브·서명·공증 스크립트

## Mac에서 실행할 순서

```bash
git clone <저장소 주소>
cd KakaoQuickLogin
brew install xcodegen
./macos/scripts/build.sh
open macos/KakaoQuickLoginMac.xcodeproj
```

Xcode에서 `KakaoQuickLoginMac` 타깃의 Development Team을 선택해 실행합니다. 시스템 설정의
개인정보 보호 및 보안 > 손쉬운 사용에서 앱을 허용한 뒤 다시 로그인합니다.

## 필수 확인

1. `build.sh`가 현재 Xcode에서 오류 없이 끝나는지
2. 최초 비밀번호가 키체인에 저장되고 다음 실행부터 입력창 없이 로그인하는지
3. 특수문자·한글 비밀번호와 비밀번호 변경·삭제가 동작하는지
4. 다른 앱이 전면이거나 카카오톡이 로그인 화면이 아닐 때 입력하지 않는지
5. 최신 카카오톡에서 `AXSecureTextField`와 로그인 버튼을 찾는지

## 알려진 미검증 사항

GitHub Actions의 macOS 환경에서 AppKit/SwiftUI Xcode 컴파일은 통과했습니다. 손쉬운 사용
권한 흐름과 최신 macOS용 카카오톡 접근성 트리는 아직 실제 Mac에서 검증하지 못했습니다.
실제 Mac 시험 결과에 따라 접근성 레이블 탐지를 조정할 수 있습니다.
