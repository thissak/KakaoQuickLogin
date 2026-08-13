using System.IO;
using System.Security.Cryptography;

namespace KakaoQuickLogin;

internal static class Program
{
    private const string AppTitle = "카카오톡 빠른 로그인";
    private const string MutexName = @"Local\KakaoQuickLogin-3F737D87-30F8-44CB-B397-259528146BA8";

    [STAThread]
    private static int Main(string[] args)
    {
        ApplicationConfiguration.Initialize();

        using var mutex = new Mutex(initiallyOwned: true, MutexName, out var ownsMutex);
        if (!ownsMutex)
        {
            ShowInfo("이미 실행 중입니다.");
            return 0;
        }

        try
        {
            var command = ParseCommand(args);
            var passwordStore = new PasswordStore();

            return command switch
            {
                AppCommand.Reset => ResetPassword(passwordStore),
                AppCommand.Forget => ForgetPassword(passwordStore),
                AppCommand.SelfTest => SelfTest.Run(),
                AppCommand.Probe => ProbeKakaoTalk(),
                AppCommand.Login => Login(passwordStore),
                _ => ShowUsageError()
            };
        }
        catch (Exception exception)
        {
            ShowError($"실행 중 오류가 발생했습니다.\n\n{exception.Message}");
            return 1;
        }
        finally
        {
            mutex.ReleaseMutex();
        }
    }

    private static int Login(PasswordStore passwordStore)
    {
        if (!passwordStore.Exists)
        {
            var newPassword = PasswordPrompt.Show(isReset: false);
            if (newPassword is null)
            {
                return 0;
            }

            try
            {
                passwordStore.Save(newPassword);
            }
            finally
            {
                Array.Clear(newPassword);
            }
        }

        byte[] passwordBytes;
        try
        {
            passwordBytes = passwordStore.Load();
        }
        catch (Exception exception) when (exception is CryptographicException or InvalidDataException)
        {
            var answer = MessageBox.Show(
                "기존 비밀번호 저장 형식을 읽을 수 없습니다.\n비밀번호를 새 형식으로 다시 저장할까요?",
                AppTitle,
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question,
                MessageBoxDefaultButton.Button1);

            if (answer != DialogResult.Yes)
            {
                return 1;
            }

            var replacementPassword = PasswordPrompt.Show(isReset: true);
            if (replacementPassword is null)
            {
                return 0;
            }

            try
            {
                passwordStore.Save(replacementPassword);
                passwordBytes = passwordStore.Load();
            }
            finally
            {
                Array.Clear(replacementPassword);
            }
        }

        try
        {
            var result = new KakaoTalkAutomation().Login(passwordBytes);
            return HandleAutomationResult(result);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(passwordBytes);
        }
    }

    private static int ResetPassword(PasswordStore passwordStore)
    {
        var newPassword = PasswordPrompt.Show(isReset: true);
        if (newPassword is null)
        {
            return 0;
        }

        try
        {
            passwordStore.Save(newPassword);
            ShowInfo("비밀번호를 안전하게 저장했습니다.");
            return 0;
        }
        finally
        {
            Array.Clear(newPassword);
        }
    }

    private static int ForgetPassword(PasswordStore passwordStore)
    {
        if (!passwordStore.Exists)
        {
            ShowInfo("저장된 비밀번호가 없습니다.");
            return 0;
        }

        var answer = MessageBox.Show(
            "이 PC에 저장된 카카오톡 비밀번호를 삭제할까요?",
            AppTitle,
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Question,
            MessageBoxDefaultButton.Button2);

        if (answer == DialogResult.Yes)
        {
            passwordStore.Delete();
            ShowInfo("저장된 비밀번호를 삭제했습니다.");
        }

        return 0;
    }

    private static int HandleAutomationResult(AutomationResult result)
    {
        switch (result)
        {
            case AutomationResult.PasswordSubmitted:
            case AutomationResult.AlreadyLoggedIn:
                return 0;
            case AutomationResult.KakaoTalkNotInstalled:
                ShowError("카카오톡 설치 경로를 찾지 못했습니다.");
                break;
            case AutomationResult.LoginWindowNotFound:
                ShowError("카카오톡 로그인 화면을 찾지 못했습니다.\n카카오톡 로그인 창을 연 뒤 다시 실행해 주세요.");
                break;
            case AutomationResult.PasswordFieldNotFound:
                ShowError("카카오톡 비밀번호 입력란을 확인하지 못했습니다.\n카카오톡 업데이트로 화면이 변경되었을 수 있습니다.");
                break;
            case AutomationResult.WindowActivationFailed:
                ShowError("카카오톡 창을 안전하게 활성화하지 못해 입력을 중단했습니다.");
                break;
            case AutomationResult.PasswordFocusFailed:
                ShowError("비밀번호 입력란의 포커스를 확인하지 못해 입력을 중단했습니다.");
                break;
            case AutomationResult.InputFailed:
                ShowError("비밀번호 입력을 완료하지 못했습니다.");
                break;
            default:
                ShowError("알 수 없는 오류로 로그인을 완료하지 못했습니다.");
                break;
        }

        return 1;
    }

    private static AppCommand? ParseCommand(string[] args)
    {
        if (args.Length == 0)
        {
            return (Control.ModifierKeys & Keys.Shift) == Keys.Shift
                ? AppCommand.Reset
                : AppCommand.Login;
        }

        if (args.Length != 1)
        {
            return null;
        }

        return args[0].ToLowerInvariant() switch
        {
            "--reset" => AppCommand.Reset,
            "--forget" => AppCommand.Forget,
            "--self-test" => AppCommand.SelfTest,
            "--probe" => AppCommand.Probe,
            _ => null
        };
    }

    private static int ShowUsageError()
    {
        ShowError("지원하지 않는 실행 옵션입니다.");
        return 2;
    }

    private static int ProbeKakaoTalk() => new KakaoTalkAutomation().Probe() switch
    {
        AutomationResult.AlreadyLoggedIn => 0,
        AutomationResult.ReadyForPassword => 20,
        AutomationResult.KakaoTalkNotInstalled => 21,
        AutomationResult.LoginWindowNotFound => 22,
        AutomationResult.PasswordFieldNotFound => 23,
        _ => 24
    };

    internal static void ShowInfo(string message) => MessageBox.Show(
        message,
        AppTitle,
        MessageBoxButtons.OK,
        MessageBoxIcon.Information);

    internal static void ShowError(string message) => MessageBox.Show(
        message,
        AppTitle,
        MessageBoxButtons.OK,
        MessageBoxIcon.Error);

    private enum AppCommand
    {
        Login,
        Reset,
        Forget,
        SelfTest,
        Probe
    }
}
