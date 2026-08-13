#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "사용법: $0 <TEAM_ID> <Developer ID Application 인증서 이름> <notarytool 프로필>" >&2
  exit 2
fi

TEAM_ID="$1"
SIGNING_IDENTITY="$2"
NOTARY_PROFILE="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPOSITORY_ROOT="$(cd "${MACOS_DIR}/.." && pwd)"
PROJECT_PATH="${MACOS_DIR}/KakaoQuickLoginMac.xcodeproj"
OUTPUT_DIR="${REPOSITORY_ROOT}/artifacts/macos"
ARCHIVE_PATH="${OUTPUT_DIR}/KakaoQuickLoginMac.xcarchive"
APP_PATH="${ARCHIVE_PATH}/Products/Applications/KakaoQuickLogin.app"
UPLOAD_ZIP="${OUTPUT_DIR}/KakaoQuickLogin-notarization.zip"
RELEASE_ZIP="${OUTPUT_DIR}/KakaoQuickLogin-0.1.0-macos-universal.zip"

"${SCRIPT_DIR}/generate-project.sh"
mkdir -p "${OUTPUT_DIR}"
rm -rf "${ARCHIVE_PATH}" "${UPLOAD_ZIP}" "${RELEASE_ZIP}"

xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme KakaoQuickLoginMac \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  DEVELOPMENT_TEAM="${TEAM_ID}" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  archive

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
ditto -c -k --keepParent "${APP_PATH}" "${UPLOAD_ZIP}"
xcrun notarytool submit "${UPLOAD_ZIP}" --keychain-profile "${NOTARY_PROFILE}" --wait
xcrun stapler staple "${APP_PATH}"
xcrun stapler validate "${APP_PATH}"
spctl --assess --type execute --verbose=2 "${APP_PATH}"

ditto -c -k --keepParent "${APP_PATH}" "${RELEASE_ZIP}"
shasum -a 256 "${RELEASE_ZIP}" > "${RELEASE_ZIP}.sha256"
echo "배포 파일: ${RELEASE_ZIP}"
