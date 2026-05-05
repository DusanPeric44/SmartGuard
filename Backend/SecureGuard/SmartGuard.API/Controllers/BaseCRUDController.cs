using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseGetController<T, TSearch>
        where T : class 
        where TSearch : BaseSearchObject 
        where TInsert : class 
        where TUpdate : class
    {
        protected readonly IBaseCRUDService<T, TSearch, TInsert, TUpdate> _crudService;

        public BaseCRUDController(IBaseCRUDService<T, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _crudService = service;
        }

        [HttpPost]
        public virtual async Task<T> Insert([FromBody] TInsert insert)
        {
            throw new NotImplementedException();
        }

        [HttpPut("{id}")]
        public virtual async Task<T> Update(int id, [FromBody] TUpdate update)
        {
            throw new NotImplementedException();
        }

        [HttpDelete("{id}")]
        public virtual async Task<bool> Delete(int id)
        {
            throw new NotImplementedException();
        }
    }
}