using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Automation;
using Microsoft.Win32;

namespace KakaoQuickLogin;

internal sealed class KakaoTalkAutomation
{
    private const string KakaoTalkProcessName = "KakaoTalk";
    private const string KakaoWindowClass = "EVA_Window_Dblclk";

    internal AutomationResult Probe()
    {
        var executablePath = FindKakaoTalkExecutable();
        if (executablePath is null)
        {
            return AutomationResult.KakaoTalkNotInstalled;
        }

        var processIds = FindVerifiedProcessIds(executablePath);
        if (processIds.Count == 0)
        {
            return AutomationResult.LoginWindowNotFound;
        }

        var windows = NativeMethods.EnumerateTopLevelWindows(processIds);
        if (windows.Count == 0)
        {
            return AutomationResult.LoginWindowNotFound;
        }

        if (FindOnlineMainWindow(windows) is not null)
        {
            return AutomationResult.AlreadyLoggedIn;
        }

        if (FindLoginTarget(windows) is not null)
        {
            return AutomationResult.ReadyForPassword;
        }

        return windows.Any(IsKakaoMainWindow)
            ? AutomationResult.PasswordFieldNotFound
            : AutomationResult.LoginWindowNotFound;
    }

    internal AutomationResult Login(ReadOnlySpan<byte> passwordBytes)
    {
        var executablePath = FindKakaoTalkExecutable();
        if (executablePath is null)
        {
            return AutomationResult.KakaoTalkNotInstalled;
        }

        var processIds = FindVerifiedProcessIds(executablePath);
        if (processIds.Count == 0)
        {
            Process.Start(new ProcessStartInfo(executablePath)
            {
                UseShellExecute = true
            });

            _ = SpinWait.SpinUntil(
                () =>
                {
                    processIds = FindVerifiedProcessIds(executablePath);
                    return processIds.Count > 0;
                },
                TimeSpan.FromSeconds(20));
        }

        if (processIds.Count == 0)
        {
            return AutomationResult.LoginWindowNotFound;
        }

        IReadOnlyList<WindowInfo> windows = [];
        _ = SpinWait.SpinUntil(
            () =>
            {
                windows = NativeMethods.EnumerateTopLevelWindows(processIds);
                return windows.Count > 0;
            },
            TimeSpan.FromSeconds(20));

        if (windows.Count == 0)
        {
            return AutomationResult.LoginWindowNotFound;
        }

        var onlineWindow = FindOnlineMainWindow(windows);
        if (onlineWindow is not null)
        {
            _ = NativeMethods.TryActivateWindow(onlineWindow.Handle, onlineWindow.ProcessId);
            return AutomationResult.AlreadyLoggedIn;
        }

        var loginTarget = FindLoginTarget(windows);
        if (loginTarget is null)
        {
            return windows.Any(IsKakaoMainWindow)
                ? AutomationResult.PasswordFieldNotFound
                : AutomationResult.LoginWindowNotFound;
        }

        if (!NativeMethods.TryActivateWindow(loginTarget.Window.Handle, loginTarget.Window.ProcessId))
        {
            return AutomationResult.WindowActivationFailed;
        }

        try
        {
            loginTarget.PasswordElement.SetFocus();
            Thread.Sleep(150);
        }
        catch (Exception exception) when (exception is COMException or InvalidOperationException)
        {
            return AutomationResult.PasswordFocusFailed;
        }

        if (!NativeMethods.IsForegroundProcess(loginTarget.Window.ProcessId))
        {
            return AutomationResult.PasswordFocusFailed;
        }

        AutomationElement? focusedElement;
        try
        {
            focusedElement = AutomationElement.FocusedElement;
        }
        catch (COMException)
        {
            return AutomationResult.PasswordFocusFailed;
        }

        if (focusedElement is null || !IsPasswordElement(focusedElement))
        {
            return AutomationResult.PasswordFocusFailed;
        }

        var characterCount = Encoding.UTF8.GetCharCount(passwordBytes);
        var characters = GC.AllocateUninitializedArray<char>(characterCount);
        try
        {
            Encoding.UTF8.GetChars(passwordBytes, characters);
            NativeMethods.ReplaceFocusedTextAndSubmit(characters);
            return AutomationResult.PasswordSubmitted;
        }
        catch (Exception exception) when (exception is ExternalException or ArgumentException)
        {
            return AutomationResult.InputFailed;
        }
        finally
        {
            CryptographicOperations.ZeroMemory(MemoryMarshal.AsBytes(characters.AsSpan()));
        }
    }

    private static LoginTarget? FindLoginTarget(IReadOnlyList<WindowInfo> windows)
    {
        foreach (var window in windows.Where(window => window.IsVisible && IsKakaoMainWindow(window)))
        {
            try
            {
                var root = AutomationElement.FromHandle(window.Handle);
                var passwordElement = root.FindFirst(
                    TreeScope.Descendants,
                    new PropertyCondition(AutomationElement.IsPasswordProperty, true));
                if (passwordElement is not null)
                {
                    return new LoginTarget(window, passwordElement);
                }
            }
            catch (Exception exception) when (exception is COMException or ElementNotAvailableException)
            {
                // The KakaoTalk UI can replace windows while it starts. A later candidate may be valid.
            }
        }

        return null;
    }

    private static WindowInfo? FindOnlineMainWindow(IReadOnlyList<WindowInfo> windows) =>
        windows
            .Where(IsKakaoMainWindow)
            .FirstOrDefault(window =>
                NativeMethods.HasDescendantWindowTitle(window.Handle, "OnlineMainView_"));

    private static bool IsPasswordElement(AutomationElement element)
    {
        try
        {
            return element.Current.IsPassword;
        }
        catch (Exception exception) when (exception is COMException or ElementNotAvailableException)
        {
            return false;
        }
    }

    private static bool IsKakaoMainWindow(WindowInfo window) =>
        string.Equals(window.ClassName, KakaoWindowClass, StringComparison.Ordinal);

    private static HashSet<int> FindVerifiedProcessIds(string executablePath)
    {
        var expectedPath = Path.GetFullPath(executablePath);
        var processIds = new HashSet<int>();

        foreach (var process in Process.GetProcessesByName(KakaoTalkProcessName))
        {
            using (process)
            {
                try
                {
                    var actualPath = process.MainModule?.FileName;
                    if (actualPath is not null &&
                        string.Equals(
                            Path.GetFullPath(actualPath),
                            expectedPath,
                            StringComparison.OrdinalIgnoreCase))
                    {
                        processIds.Add(process.Id);
                    }
                }
                catch (Exception exception) when (exception is InvalidOperationException or System.ComponentModel.Win32Exception)
                {
                    // Ignore processes whose executable path cannot be verified.
                }
            }
        }

        return processIds;
    }

    private static string? FindKakaoTalkExecutable()
    {
        var candidates = new List<string?>
        {
            ReadAppPath(),
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
                "Kakao", "KakaoTalk", "KakaoTalk.exe"),
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                "Kakao", "KakaoTalk", "KakaoTalk.exe"),
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Kakao", "KakaoTalk", "KakaoTalk.exe")
        };

        return candidates
            .Where(path => !string.IsNullOrWhiteSpace(path))
            .Select(path => Path.GetFullPath(path!))
            .FirstOrDefault(File.Exists);
    }

    private static string? ReadAppPath()
    {
        const string keyPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\KakaoTalk.exe";
        using var key = Registry.LocalMachine.OpenSubKey(keyPath)
            ?? Registry.CurrentUser.OpenSubKey(keyPath);
        return key?.GetValue(null) as string;
    }

    private sealed record LoginTarget(WindowInfo Window, AutomationElement PasswordElement);
}

internal enum AutomationResult
{
    PasswordSubmitted,
    AlreadyLoggedIn,
    ReadyForPassword,
    KakaoTalkNotInstalled,
    LoginWindowNotFound,
    PasswordFieldNotFound,
    WindowActivationFailed,
    PasswordFocusFailed,
    InputFailed
}
