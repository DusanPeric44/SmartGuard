using System.IO;
using System.Threading.Tasks;

namespace SmartGuard.Model.Interfaces
{
    public interface IFileStorageService
    {
        Task<string> SaveImageAsync(byte[] bytes, string extension);
        Task<string> SaveFileAsync(byte[] bytes, string extension, string? subfolder = null);
        Task DeleteAsync(string urlPath);
        Task<(Stream Stream, string ContentType)> OpenReadAsync(string urlPath);
    }
}
