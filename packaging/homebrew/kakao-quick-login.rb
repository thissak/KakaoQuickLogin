cask "kakao-quick-login" do
  version "0.1.1"
  sha256 "91a9ff988f535a9e50bda994231156cb0bedd8533a6d11684abd35c334c68d50"

  url "https://github.com/thissak/KakaoQuickLogin/releases/download/v#{version}/KakaoQuickLogin-#{version}-macos-universal.zip",
      verified: "github.com/thissak/KakaoQuickLogin/"
  name "KakaoQuickLogin"
  name "카카오톡 빠른 로그인"
  desc "Fills the saved password on the KakaoTalk login screen"
  homepage "https://goldenlabs.dev/"

  depends_on macos: :ventura

  app "KakaoQuickLogin.app"

  uninstall quit: "dev.goldenlabs.KakaoQuickLogin"

  zap trash: [
    "~/Library/Preferences/dev.goldenlabs.KakaoQuickLogin.plist",
    "~/Library/Saved Application State/dev.goldenlabs.KakaoQuickLogin.savedState",
  ]

  caveats <<~EOS
    KakaoQuickLogin needs Accessibility permission to read the KakaoTalk login
    window and type the saved password. Grant it in
    System Settings > Privacy & Security > Accessibility on first launch.

    The password is stored in your login keychain. Remove it before uninstalling
    with the app's Settings > "저장된 비밀번호 삭제" — `brew uninstall` and `zap`
    cannot delete keychain items.

    Not an official Kakao product; not affiliated with or endorsed by Kakao.
  EOS
end
