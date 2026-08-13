using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace KakaoQuickLogin;

internal static class SelfTest
{
    internal static int Run()
    {
        var testDirectory = Path.Combine(
            Path.GetTempPath(),
            $"KakaoQuickLogin-SelfTest-{Guid.NewGuid():N}");
        Directory.CreateDirectory(testDirectory);

        var expectedCharacters = "테스트-password-!+^%{}[]".ToCharArray();
        byte[]? actualBytes = null;

        try
        {
            var store = new PasswordStore(testDirectory);
            store.Save(expectedCharacters);

            if (!store.Exists)
            {
                return 10;
            }

            actualBytes = store.Load();
            var expectedBytes = Encoding.UTF8.GetBytes(expectedCharacters);
            try
            {
                if (!CryptographicOperations.FixedTimeEquals(actualBytes, expectedBytes))
                {
                    return 11;
                }
            }
            finally
            {
                CryptographicOperations.ZeroMemory(expectedBytes);
            }

            store.Delete();
            return store.Exists ? 12 : 0;
        }
        catch
        {
            return 13;
        }
        finally
        {
            Array.Clear(expectedCharacters);
            if (actualBytes is not null)
            {
                CryptographicOperations.ZeroMemory(actualBytes);
            }

            if (Directory.Exists(testDirectory))
            {
                Directory.Delete(testDirectory, recursive: false);
            }
        }
    }
}
