using System.Collections.Generic;
using System.Threading.Tasks;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface IBaseGetService<T, TSearch> where TSearch : BaseSearchObject
    {
        Task<PagedResult<T>> GetAsync(TSearch search = null);
        Task<T> GetByIdAsync(int id);
    }
}