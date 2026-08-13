#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen이 필요합니다: brew install xcodegen" >&2
  exit 1
fi

cd "${MACOS_DIR}"
xcodegen generate --spec project.yml
echo "생성 완료: ${MACOS_DIR}/KakaoQuickLoginMac.xcodeproj"
