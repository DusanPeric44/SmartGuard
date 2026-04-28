using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class BaseGetController<T, TSearch> : ControllerBase where TSearch : BaseSearchObject
    {
        protected readonly IBaseGetService<T, TSearch> _service;

        public BaseGetController(IBaseGetService<T, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public virtual async Task<PagedResult<T>> Get([FromQuery] TSearch search = null)
        {
            return await _service.GetAsync(search);
        }

        [HttpGet("{id}")]
        public virtual async Task<T> GetById(int id)
        {
            return await _service.GetByIdAsync(id);
        }
    }
}