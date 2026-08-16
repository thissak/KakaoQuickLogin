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
# 배포 파일 이름은 Info.plist의 버전을 따라간다. 하드코딩하면 버전을 올린 뒤 옛 이름으로
# 덮어써서 이미 공개된 zip과 Cask의 sha256이 어긋난다.
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "${MACOS_DIR}/Resources/Info.plist")"
RELEASE_ZIP="${OUTPUT_DIR}/KakaoQuickLogin-${VERSION}-macos-universal.zip"

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
# 릴리스에 함께 올리는 파일이므로 빌드한 Mac의 절대 경로(사용자 계정명 포함)가 남지
# 않도록 파일 이름만 적는다. shasum은 인자로 준 경로를 그대로 출력한다.
RELEASE_ZIP_NAME="$(basename "${RELEASE_ZIP}")"
(cd "${OUTPUT_DIR}" && shasum -a 256 "${RELEASE_ZIP_NAME}" > "${RELEASE_ZIP_NAME}.sha256")
echo "배포 파일: ${RELEASE_ZIP}"
