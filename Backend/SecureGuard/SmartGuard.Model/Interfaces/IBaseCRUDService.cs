using System.Threading.Tasks;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.Model.Interfaces
{
    public interface IBaseCRUDService<T, TSearch, TInsert, TUpdate> : IBaseGetService<T, TSearch> where TSearch : BaseSearchObject
    {
        Task<T> InsertAsync(TInsert insert);
        Task<T> UpdateAsync(int id, TUpdate update);
        Task<bool> DeleteAsync(int id);
    }
}