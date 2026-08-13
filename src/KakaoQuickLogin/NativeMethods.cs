using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

namespace KakaoQuickLogin;

internal static class NativeMethods
{
    private const uint InputKeyboard = 1;
    private const uint KeyEventKeyUp = 0x0002;
    private const uint KeyEventUnicode = 0x0004;
    private const ushort VirtualKeyControl = 0x11;
    private const ushort VirtualKeyA = 0x41;
    private const ushort VirtualKeyReturn = 0x0D;
    private const int ShowRestore = 9;

    internal static IReadOnlyList<WindowInfo> EnumerateTopLevelWindows(ISet<int> processIds)
    {
        var windows = new List<WindowInfo>();
        EnumWindows((windowHandle, state) =>
        {
            _ = GetWindowThreadProcessId(windowHandle, out var processId);
            if (!processIds.Contains(unchecked((int)processId)))
            {
                return true;
            }

            windows.Add(new WindowInfo(
                windowHandle,
                unchecked((int)processId),
                GetClassName(windowHandle),
                GetWindowTitle(windowHandle),
                IsWindowVisible(windowHandle)));
            return true;
        }, IntPtr.Zero);

        return windows;
    }

    internal static bool HasDescendantWindowTitle(IntPtr parentHandle, string titlePrefix)
    {
        var found = false;
        EnumChildWindows(parentHandle, (windowHandle, state) =>
        {
            if (GetWindowTitle(windowHandle).StartsWith(titlePrefix, StringComparison.Ordinal))
            {
                found = true;
                return false;
            }

            return true;
        }, IntPtr.Zero);

        return found;
    }

    internal static bool TryActivateWindow(IntPtr windowHandle, int expectedProcessId)
    {
        _ = ShowWindowAsync(windowHandle, ShowRestore);
        _ = SetForegroundWindow(windowHandle);
        Thread.Sleep(200);

        var foregroundWindow = GetForegroundWindow();
        if (foregroundWindow == IntPtr.Zero)
        {
            return false;
        }

        _ = GetWindowThreadProcessId(foregroundWindow, out var processId);
        return unchecked((int)processId) == expectedProcessId;
    }

    internal static bool IsForegroundProcess(int expectedProcessId)
    {
        var foregroundWindow = GetForegroundWindow();
        if (foregroundWindow == IntPtr.Zero)
        {
            return false;
        }

        _ = GetWindowThreadProcessId(foregroundWindow, out var processId);
        return unchecked((int)processId) == expectedProcessId;
    }

    internal static void ReplaceFocusedTextAndSubmit(ReadOnlySpan<char> text)
    {
        SendVirtualKeyChord(VirtualKeyControl, VirtualKeyA);

        Span<Input> inputs = stackalloc Input[2];
        foreach (var character in text)
        {
            inputs[0] = CreateUnicodeInput(character, keyUp: false);
            inputs[1] = CreateUnicodeInput(character, keyUp: true);
            SendInputs(inputs);
        }

        Span<Input> enterInputs = stackalloc Input[2];
        enterInputs[0] = CreateVirtualKeyInput(VirtualKeyReturn, keyUp: false);
        enterInputs[1] = CreateVirtualKeyInput(VirtualKeyReturn, keyUp: true);
        SendInputs(enterInputs);
    }

    private static void SendVirtualKeyChord(ushort modifier, ushort key)
    {
        Span<Input> inputs = stackalloc Input[4];
        inputs[0] = CreateVirtualKeyInput(modifier, keyUp: false);
        inputs[1] = CreateVirtualKeyInput(key, keyUp: false);
        inputs[2] = CreateVirtualKeyInput(key, keyUp: true);
        inputs[3] = CreateVirtualKeyInput(modifier, keyUp: true);
        SendInputs(inputs);
    }

    private static Input CreateVirtualKeyInput(ushort virtualKey, bool keyUp) => new()
    {
        Type = InputKeyboard,
        Data = new InputUnion
        {
            Keyboard = new KeyboardInput
            {
                VirtualKey = virtualKey,
                Flags = keyUp ? KeyEventKeyUp : 0
            }
        }
    };

    private static Input CreateUnicodeInput(char character, bool keyUp) => new()
    {
        Type = InputKeyboard,
        Data = new InputUnion
        {
            Keyboard = new KeyboardInput
            {
                ScanCode = character,
                Flags = KeyEventUnicode | (keyUp ? KeyEventKeyUp : 0)
            }
        }
    };

    private static void SendInputs(ReadOnlySpan<Input> inputs)
    {
        var array = inputs.ToArray();
        var sent = SendInput(
            unchecked((uint)array.Length),
            array,
            Marshal.SizeOf<Input>());

        if (sent != array.Length)
        {
            throw new Win32Exception(Marshal.GetLastWin32Error(), "Windows rejected keyboard input.");
        }
    }

    private static string GetWindowTitle(IntPtr windowHandle)
    {
        var length = GetWindowTextLength(windowHandle);
        var builder = new StringBuilder(Math.Max(length + 1, 2));
        _ = GetWindowText(windowHandle, builder, builder.Capacity);
        return builder.ToString();
    }

    private static string GetClassName(IntPtr windowHandle)
    {
        var builder = new StringBuilder(256);
        _ = GetClassName(windowHandle, builder, builder.Capacity);
        return builder.ToString();
    }

    private delegate bool EnumWindowsCallback(IntPtr windowHandle, IntPtr state);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EnumWindows(EnumWindowsCallback callback, IntPtr state);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EnumChildWindows(
        IntPtr parentWindow,
        EnumWindowsCallback callback,
        IntPtr state);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int GetWindowText(IntPtr windowHandle, StringBuilder text, int maximumCount);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int GetWindowTextLength(IntPtr windowHandle);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int GetClassName(IntPtr windowHandle, StringBuilder className, int maximumCount);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool IsWindowVisible(IntPtr windowHandle);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr windowHandle, out uint processId);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool ShowWindowAsync(IntPtr windowHandle, int command);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetForegroundWindow(IntPtr windowHandle);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint inputCount, Input[] inputs, int inputSize);

    [StructLayout(LayoutKind.Sequential)]
    private struct Input
    {
        internal uint Type;
        internal InputUnion Data;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct InputUnion
    {
        [FieldOffset(0)]
        internal KeyboardInput Keyboard;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct KeyboardInput
    {
        internal ushort VirtualKey;
        internal ushort ScanCode;
        internal uint Flags;
        internal uint Time;
        internal UIntPtr ExtraInfo;
    }
}

internal sealed record WindowInfo(
    IntPtr Handle,
    int ProcessId,
    string ClassName,
    string Title,
    bool IsVisible);
