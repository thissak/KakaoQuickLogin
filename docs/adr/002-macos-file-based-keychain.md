# ADR 002: macOS는 파일 기반 키체인을 사용한다

- 상태: 승인
- 날짜: 2026-08-14
- 관계: [ADR 001](001-platform-native-security-and-automation.md)의 "macOS는 데이터 보호
  키체인을 사용한다" 부분을 대체합니다. ADR 001의 나머지 결정(플랫폼별 네이티브 UI,
  Accessibility 자동화, 입력 전 검증)은 그대로 유효합니다.

## 배경

ADR 001은 macOS 저장소로 데이터 보호 키체인을 선택했습니다. 실제 Mac에서 처음 앱을
실행하자 비밀번호 저장이 `-34018`(`errSecMissingEntitlement`)로 실패했습니다.

Apple 기술문서 [TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)은
그 이유를 이렇게 밝힙니다.

> macOS builds the list of data protection keychain access groups available to your program
> from its code signing entitlements. **These entitlements must be authorized by a
> provisioning profile.** Your program needs an app-like bundle structure in which to embed
> that profile.

즉 데이터 보호 키체인을 쓰려면 키체인 접근 그룹 entitlement와 **그것을 승인하는
프로비저닝 프로파일을 앱 번들에 임베드**해야 합니다. 이 앱의 entitlements는 비어 있고
프로파일도 없어 접근 그룹이 하나도 만들어지지 않았습니다.

재현 스크립트로 두 구현을 같은 조건에서 비교해 확인했습니다.

| 구현 | 조회 | 저장 | 읽기 | 삭제 |
|---|---|---|---|---|
| 데이터 보호 키체인 | -25300 | **-34018** | -25300 | **-34018** |
| 파일 기반 키체인 | -25300 | 0 | 0 (값 일치) | 0 |

## 검토한 선택지

1. **파일 기반 키체인으로 전환** — `kSecUseDataProtectionKeychain`을 제거합니다.
   entitlement도 프로비저닝 프로파일도 필요 없습니다.
2. **데이터 보호 키체인 유지** — App ID 등록, `keychain-access-groups` entitlement 추가,
   macOS Developer ID 프로비저닝 프로파일 발급·임베드, 재서명·재공증이 필요합니다.

TN3137은 일반적으로 데이터 보호 키체인을 기본값으로 삼으라고 권합니다. 그러나 이 앱은
App Store 밖에서 Developer ID로 배포하는 개인 유틸리티이고, 2안은 만료되는 프로비저닝
프로파일이라는 관리 대상을 늘립니다. 사용하는 기능(일반 암호 항목 저장·조회·삭제)은
파일 기반 키체인으로 충분합니다.

## 결정

macOS는 **파일 기반 로그인 키체인**에 일반 암호 항목으로 비밀번호를 저장합니다.
`kSecUseDataProtectionKeychain`을 지정하지 않아 `SecItem` API가 기본값인 파일 기반
키체인을 대상으로 하게 합니다.

`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`도 함께 제거했습니다. 이 속성은 데이터
보호 키체인에만 적용되므로 파일 기반 경로에서는 아무 보호도 하지 않으면서 보호하는 것처럼
보이게 만듭니다.

## 결과

- 접근 제어 모델이 바뀝니다. 접근 그룹 대신 **앱 코드서명에 묶인 ACL**이 항목을 보호하며,
  다른 앱이 읽으려 하면 macOS가 사용자 승인을 요구합니다.
- 비밀번호를 서버로 보내지 않고 평문 파일·클립보드에 저장하지 않는다는 원칙은 그대로입니다.
- Windows(DPAPI `CurrentUser`)와 macOS의 저장소가 서로 다른 것은 ADR 001의 방침대로입니다.
- TN3137은 파일 기반 키체인이 "on the road to deprecation"이라고 밝힙니다. 공식 폐기는
  아니지만, Apple이 폐기를 예고하거나 이 앱이 iCloud 동기화·Secure Enclave·생체 인증을
  필요로 하게 되면 2안(프로비저닝 프로파일 구성)으로 다시 검토합니다.
