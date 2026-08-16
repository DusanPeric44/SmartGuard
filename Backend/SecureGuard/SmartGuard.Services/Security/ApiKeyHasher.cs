using System.Security.Cryptography;
using System.Text;

namespace SmartGuard.Services.Security
{
    public static class ApiKeyHasher
    {
        public static string Hash(string rawKey)
        {
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(rawKey));
            return Convert.ToHexString(bytes);
        }

        public static bool Verify(string? rawKey, string? storedHash)
        {
            if (string.IsNullOrEmpty(rawKey) || string.IsNullOrEmpty(storedHash))
            {
                return false;
            }

            var computedHash = Hash(rawKey);
            return CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(computedHash),
                Encoding.UTF8.GetBytes(storedHash));
        }
    }
}
