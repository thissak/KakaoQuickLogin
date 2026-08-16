# macOS 서명·공증 인계 (2026-08-13)

기존 [macos-build-handoff.md](macos-build-handoff.md)는 "Mac에서 실행할 순서"를 안내한
문서다. 이 문서는 **실제 Mac에서 빌드·서명·공증을 완료한 결과**를 남긴다.

## 현재 상태

| 단계 | 결과 |
|---|---|
| Debug 컴파일 검증 (`macos/scripts/build.sh`) | ✅ BUILD SUCCEEDED (Xcode 26.6 / macOS 26.5.2) |
| 개발 서명 Release 빌드 | ✅ 유니버설(arm64+x86_64), `artifacts/macos/KakaoQuickLogin.app` |
| Developer ID Application 인증서 발급 | ✅ 2026-08-13 발급 |
| Developer ID 아카이브 | ✅ `artifacts/macos/KakaoQuickLoginMac.xcarchive` |
| 공증 (notarization) | ✅ **Accepted** (아래 참조) |
| 스테이플·`spctl` 검증·배포 ZIP | ✅ 완료 |
| 실제 카카오톡 연동 검증 | ✅ **통과** (2026-08-14, 아래 E2E 참조) |

**배포 산출물** — 다른 Mac에 전달해도 Gatekeeper 경고 없이 실행된다.
실행 검증에서 결함 3건을 고친 뒤 재빌드·재공증한 최종본이다.

| 항목 | 값 |
|---|---|
| 파일 | `artifacts/macos/KakaoQuickLogin-0.1.0-macos-universal.zip` (164 KB) |
| SHA-256 | `b3ae0c6cf2eddb805202676611aef1bac2a3df6e4be2eb8397dbdcb90cdad472` |
| 공증 Submission ID | `effc5543-c34c-4773-8eaf-4da62640a20c` (2026-08-14, 약 2분) |

## E2E 실행 검증 (2026-08-14)

카카오톡이 **비전면**인 상태에서 앱을 실행하고, 별도 관찰 스크립트로 두 앱의 AX 트리를
0.5초 간격으로 추적했다.

```
07:12:54  카톡 : 창=['로그인'] 입력란글자수=0  로그인버튼 enabled=false   (전면=터미널)
07:12:57  앱 실행
07:12:58  앱   : "로그인 요청 완료. 카카오톡에 비밀번호를 입력하고 로그인 버튼을 눌렀습니다."
07:12:58  카톡 : 입력란글자수=20  로그인버튼 enabled=true
07:13:00  카톡 : 로그인버튼 없음
07:13:07  카톡 : 창=['카카오톡']                                        ← 로그인 성공
```

앱 실행부터 로그인 요청까지 약 1초. 키체인 항목 존재는
`security find-generic-password -s io.github.thissak.KakaoQuickLogin`으로 확인했다.

> 07:13:30에 카카오톡이 스스로 로그인 창으로 되돌아갔다. 다중 기기 로그아웃 정책
> ("다른 기기에서 로그인해 로그아웃 되었습니다")으로 보이며 이 앱의 동작 밖이다.

### 실행 검증에서 발견해 고친 결함 3건

1. **키체인 `-34018`** — 데이터 보호 키체인에 필요한 entitlement·프로비저닝 프로파일이
   없었다. 파일 기반 키체인으로 전환([ADR 002](../adr/002-macos-file-based-keychain.md)).
2. **QR 버튼 오선택** — 로그인 버튼을 부분 일치로 찾아 `  QR코드 로그인`이 잡혔다.
   공백 제거 후 정확 일치로 좁히고, 버튼 탐색을 비밀번호 입력 뒤로 옮겼다.
3. **창이 내려가 있으면 실패** — `NSRunningApplication.activate`는 앱을 앞으로 가져올 뿐
   창을 띄우지 않는다. `NSWorkspace.openApplication`(Dock 클릭과 같은 reopen 경로)으로
   바꿨다. 근거: Apple `applicationShouldHandleReopen(_:hasVisibleWindows:)` 문서.

아카이브 서명 검증 결과:

```
Authority=Developer ID Application: Daeuk Kim (MSM4LGSYRY)
TeamIdentifier=MSM4LGSYRY
CodeDirectory flags=0x10000(runtime)      # 하드닝된 런타임
Timestamp=Aug 13, 2026 at 10:12:09 PM     # 보안 타임스탬프
codesign --verify --deep --strict → valid on disk / satisfies its Designated Requirement
lipo -archs → x86_64 arm64
```

## 공증 결과

| 항목 | 값 |
|---|---|
| Submission ID | `a671805f-57c0-4987-b931-814ca86b57d4` |
| 제출 → 완료 | 2026-08-13 22:17 → 22:59 KST (**약 42분**) |
| 상태 | `Accepted` |
| 스테이플 | `The staple and validate action worked!` |
| Gatekeeper | `accepted` / `source=Notarized Developer ID` |
| notarytool 프로필 | `KakaoQuickLogin-notary` (키체인 저장) |

Apple 안내는 "대부분 15분 이내"인데 42분이 걸렸다. 제출 당시 Apple 시스템 상태는 정상
(`Developer ID Notary Service: Available`)이었다. 새로 발급한 Developer ID 인증서의 첫
제출이 지연되는 경향이 있다는 관찰이 있으나 Apple이 문서화한 동작은 아니다. **다음 공증
때 40분씩 걸린다고 미리 단정하지 말 것.**

### 다음 릴리스에서 다시 공증할 때

```bash
./macos/scripts/archive-and-notarize.sh "MSM4LGSYRY" \
  "Developer ID Application: Daeuk Kim (MSM4LGSYRY)" "KakaoQuickLogin-notary"
```

공증 대기 중 세션이 끊겨도 **Apple 서버의 심사는 계속된다.** 끊기는 것은 결과를 받아
티켓을 붙이는 로컬 단계뿐이므로, Submission ID로 이어붙인다. 이때 스크립트를 처음부터 다시
돌리면 **재아카이브 후 새로 제출**하므로 대기 중인 제출이 버려진다.

```bash
APP=artifacts/macos/KakaoQuickLoginMac.xcarchive/Products/Applications/KakaoQuickLogin.app
xcrun notarytool wait <Submission ID> --keychain-profile KakaoQuickLogin-notary
xcrun stapler staple "$APP" && xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=2 "$APP"
ditto -c -k --keepParent "$APP" artifacts/macos/KakaoQuickLogin-<버전>-macos-universal.zip
```

실패(`Invalid`)로 끝나면 사유를 먼저 확인한다:

```bash
xcrun notarytool log <Submission ID> --keychain-profile KakaoQuickLogin-notary
```

## 코드 변경

**`macos/project.yml`에서 `info:`·`entitlements:` 키를 제거했다.**

XcodeGen에서 이 두 키는 "해당 경로에 파일을 **생성**하라"는 뜻이라, `generate-project.sh`가
돌 때마다 저장소의 `Resources/Info.plist`를 기본 템플릿으로 덮어썼다. 실제로 첫 빌드에서
`CFBundleDisplayName`(`카카오톡 빠른 로그인`)·`CFBundleShortVersionString`(`0.1.0` →
`1.0`)·`LSMinimumSystemVersion`·`NSPrincipalClass`·`LSApplicationCategoryType`이 전부
사라졌다. 두 파일은 이미 타깃 설정의 `INFOPLIST_FILE`·`CODE_SIGN_ENTITLEMENTS`로
연결되어 있어 키 제거로 동작 변화는 없다. 제거 후 재생성해도 소스가 변경되지 않음을 확인했다.

## 서명 환경

이 Mac에서 확인한 값이며, 계정·인증서 상세는 글로벌 레퍼런스
`~/.claude/reference/apple-developer.md`에 정리했다.

| 항목 | 값 |
|---|---|
| Team ID | `MSM4LGSYRY` (Daeuk Kim, 개인 유료 멤버십) |
| 서명 인증서 | `Developer ID Application: Daeuk Kim (MSM4LGSYRY)` |
| 배포 스크립트 인자 | `./macos/scripts/archive-and-notarize.sh "MSM4LGSYRY" "Developer ID Application: Daeuk Kim (MSM4LGSYRY)" "KakaoQuickLogin-notary"` |

## 다음 작업

1. 서명된 앱을 실행해 **실제 카카오톡 연동 검증** — 손쉬운 사용 권한 허용, 키체인 저장,
   비밀번호 변경·삭제, 비로그인 화면에서 입력 차단. 기존 handoff의 "필수 확인" 5개 항목.
2. 검증 통과 후 `PROGRESS.md`의 "macOS 키체인·손쉬운 사용과 최신 카카오톡 연동" 항목 갱신
3. 공개 배포 시 `docs/DISTRIBUTION.md` 점검표 수행

## 알려진 이슈

- **Developer ID 인증서 만료가 2027-02-01로 짧다.** 만료 후에도 이미 공증된 배포본은
  실행되지만 새 서명은 불가하다. 그 전에 Xcode에서 재발급한다.
- **앱을 한 번도 실행하지 않았다.** 실행 시 손쉬운 사용 권한 요청과 실제 카카오톡 로그인
  시도가 발생하므로 의도적으로 보류했다. 위 "다음 작업" 1번이 남은 검증 전부다.
  → 2026-08-14 실제 Mac에서 로그인 동작까지 확인했다. `PROGRESS.md` 참고.
- ~~`archive-and-notarize.sh`의 릴리스 ZIP 이름에 버전 `0.1.0`이 하드코딩되어 있다.~~
  → 2026-08-16 해결. 스크립트가 `Info.plist`의 `CFBundleShortVersionString`을 읽어
  이름을 만든다.
- `artifacts/macos/`에 중간 산출물이 남아 있다 — `KakaoQuickLogin-notarization.zip`(공증
  업로드용)과 `KakaoQuickLogin-0.1.0-macos-universal-dev.zip`(개발 서명 빌드, 공증 전).
  **배포용은 접미사 없는 `KakaoQuickLogin-0.1.0-macos-universal.zip` 하나뿐이다.**
  `artifacts/`는 `.gitignore` 대상이라 커밋되지는 않는다.
