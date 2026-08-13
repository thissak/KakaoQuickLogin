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
- macOS 프로젝트 YAML·Swift 구문 정적 검사: 통과
- macOS 실제 Xcode 컴파일과 최신 카카오톡 연동: Mac에서 확인 필요

## 다음 작업

1. Mac에서 `./macos/scripts/build.sh`를 실행해 실제 Xcode 컴파일을 확인합니다.
2. Xcode에서 Development Team을 선택하고 키체인·손쉬운 사용·최신 카카오톡 연동을 시험합니다.
3. 공개 배포 시 Developer ID 서명과 Apple 공증을 적용합니다.
