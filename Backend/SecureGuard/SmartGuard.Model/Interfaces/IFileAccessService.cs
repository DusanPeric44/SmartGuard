using System.Threading.Tasks;

namespace SmartGuard.Model.Interfaces
{
    public interface IFileAccessService
    {
        /// <summary>
        /// Decides whether the current caller may read the file behind <paramref name="urlPath"/>.
        /// Files under /uploads are private (face captures, recordings, report PDFs), so a path is
        /// only served when it resolves to a resource the caller is entitled to see.
        /// </summary>
        Task<bool> CanViewAsync(string urlPath);
    }
}
