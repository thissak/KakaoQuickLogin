using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace KakaoQuickLogin;

internal sealed class PasswordStore
{
    private static readonly byte[] Magic = "KQL1"u8.ToArray();
    private static readonly byte[] Entropy = "KakaoQuickLogin:password:v1"u8.ToArray();

    private readonly string _secretPath;

    internal PasswordStore()
        : this(Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "KakaoQuickLogin"))
    {
    }

    internal PasswordStore(string storageDirectory)
    {
        _secretPath = Path.Combine(storageDirectory, "password.dat");
    }

    internal bool Exists => File.Exists(_secretPath);

    internal void Save(ReadOnlySpan<char> password)
    {
        if (password.IsEmpty)
        {
            throw new ArgumentException("Password cannot be empty.", nameof(password));
        }

        var byteCount = Encoding.UTF8.GetByteCount(password);
        var plainBytes = GC.AllocateUninitializedArray<byte>(byteCount);
        byte[]? protectedBytes = null;

        try
        {
            Encoding.UTF8.GetBytes(password, plainBytes);
            protectedBytes = ProtectedData.Protect(
                plainBytes,
                Entropy,
                DataProtectionScope.CurrentUser);

            var payload = new byte[Magic.Length + protectedBytes.Length];
            Magic.CopyTo(payload, 0);
            protectedBytes.CopyTo(payload, Magic.Length);
            WriteAtomically(payload);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(plainBytes);
            if (protectedBytes is not null)
            {
                CryptographicOperations.ZeroMemory(protectedBytes);
            }
        }
    }

    internal byte[] Load()
    {
        var payload = File.ReadAllBytes(_secretPath);
        if (payload.Length <= Magic.Length || !payload.AsSpan(0, Magic.Length).SequenceEqual(Magic))
        {
            throw new InvalidDataException("Unknown password file format.");
        }

        var protectedBytes = payload.AsSpan(Magic.Length).ToArray();
        try
        {
            return ProtectedData.Unprotect(
                protectedBytes,
                Entropy,
                DataProtectionScope.CurrentUser);
        }
        finally
        {
            CryptographicOperations.ZeroMemory(protectedBytes);
            CryptographicOperations.ZeroMemory(payload);
        }
    }

    internal void Delete()
    {
        if (File.Exists(_secretPath))
        {
            File.Delete(_secretPath);
        }
    }

    private void WriteAtomically(byte[] payload)
    {
        var directory = Path.GetDirectoryName(_secretPath)
            ?? throw new InvalidOperationException("Password storage directory is unavailable.");

        Directory.CreateDirectory(directory);
        var temporaryPath = Path.Combine(directory, $"password-{Guid.NewGuid():N}.tmp");

        try
        {
            using (var stream = new FileStream(
                temporaryPath,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None,
                bufferSize: 4096,
                FileOptions.WriteThrough))
            {
                stream.Write(payload);
                stream.Flush(flushToDisk: true);
            }

            File.Move(temporaryPath, _secretPath, overwrite: true);
        }
        finally
        {
            if (File.Exists(temporaryPath))
            {
                File.Delete(temporaryPath);
            }

            CryptographicOperations.ZeroMemory(payload);
        }
    }
}
