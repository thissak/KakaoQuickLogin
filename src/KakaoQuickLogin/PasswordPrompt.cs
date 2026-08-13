namespace KakaoQuickLogin;

internal sealed class PasswordPrompt : Form
{
    private readonly TextBox _passwordBox;
    private char[]? _password;

    private PasswordPrompt(bool isReset)
    {
        Text = "카카오톡 빠른 로그인";
        ClientSize = new Size(410, 185);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        TopMost = true;
        ShowInTaskbar = true;

        var label = new Label
        {
            AutoSize = true,
            Location = new Point(22, 20),
            Text = isReset
                ? "새 카카오톡 비밀번호를 입력해 주세요."
                : "카카오톡 비밀번호를 입력해 주세요."
        };

        _passwordBox = new TextBox
        {
            Location = new Point(24, 52),
            Size = new Size(360, 27),
            UseSystemPasswordChar = true,
            TabIndex = 0
        };

        var securityNote = new Label
        {
            AutoSize = true,
            ForeColor = SystemColors.GrayText,
            Location = new Point(22, 88),
            Text = "이 PC의 현재 Windows 사용자만 복호화할 수 있습니다."
        };

        var saveButton = new Button
        {
            Location = new Point(228, 128),
            Size = new Size(75, 32),
            Text = "저장",
            TabIndex = 1
        };
        saveButton.Click += SaveButton_Click;

        var cancelButton = new Button
        {
            DialogResult = DialogResult.Cancel,
            Location = new Point(309, 128),
            Size = new Size(75, 32),
            Text = "취소",
            TabIndex = 2
        };

        AcceptButton = saveButton;
        CancelButton = cancelButton;
        Controls.AddRange([label, _passwordBox, securityNote, saveButton, cancelButton]);
        Shown += (_, _) => _passwordBox.Focus();
    }

    internal static char[]? Show(bool isReset)
    {
        using var prompt = new PasswordPrompt(isReset);
        return prompt.ShowDialog() == DialogResult.OK
            ? prompt.TakePassword()
            : null;
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _passwordBox.Clear();
            if (_password is not null)
            {
                Array.Clear(_password);
                _password = null;
            }
        }

        base.Dispose(disposing);
    }

    private void SaveButton_Click(object? sender, EventArgs eventArgs)
    {
        if (_passwordBox.TextLength == 0)
        {
            MessageBox.Show(
                "비밀번호를 입력해 주세요.",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
            _passwordBox.Focus();
            return;
        }

        _password = _passwordBox.Text.ToCharArray();
        _passwordBox.Clear();
        DialogResult = DialogResult.OK;
        Close();
    }

    private char[] TakePassword()
    {
        var password = _password
            ?? throw new InvalidOperationException("Password was not captured.");
        _password = null;
        return password;
    }
}
