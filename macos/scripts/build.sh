#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_PATH="${MACOS_DIR}/KakaoQuickLoginMac.xcodeproj"
DERIVED_DATA="${MACOS_DIR}/build/DerivedData"

"${SCRIPT_DIR}/generate-project.sh"

xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme KakaoQuickLoginMac \
  -configuration Debug \
  -derivedDataPath "${DERIVED_DATA}" \
  CODE_SIGNING_ALLOWED=NO \
  clean build

APP_PATH="${DERIVED_DATA}/Build/Products/Debug/KakaoQuickLogin.app"
test -d "${APP_PATH}"
echo "빌드 완료: ${APP_PATH}"
echo "실행 테스트에는 Xcode에서 Development Team을 선택해 서명한 앱을 사용하세요."
