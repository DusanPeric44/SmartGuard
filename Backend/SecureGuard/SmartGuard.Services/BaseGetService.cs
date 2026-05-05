using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Mapster;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

namespace SmartGuard.Services
{
    public abstract class BaseGetService<T, TDb, TSearch> : IBaseGetService<T, TSearch> 
        where TDb : class 
        where T : class 
        where TSearch : BaseSearchObject
    {
        protected readonly SmartGuardContext _context;

        public BaseGetService(SmartGuardContext context)
        {
            _context = context;
        }

        public virtual async Task<PagedResult<T>> GetAsync(TSearch search = null)
        {
            var query = _context.Set<TDb>().AsQueryable();

            if (typeof(ISoftDeletable).IsAssignableFrom(typeof(TDb)))
            {
                query = query.Where(x => !((ISoftDeletable)x).IsDeleted);
            }

            query = AddFilter(query, search);
            query = AddInclude(query, search);

            int count = await query.CountAsync();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                // Max PageSize = 100
                int pageSize = search.PageSize.Value > 100 ? 100 : search.PageSize.Value;
                query = query.Skip((search.Page.Value - 1) * pageSize).Take(pageSize);
            }

            var list = await query.ToListAsync();

            return new PagedResult<T>()
            {
                Result = list.Adapt<IEnumerable<T>>(),
                Count = count
            };
        }

        public virtual async Task<T> GetByIdAsync(int id)
        {
            var entity = await _context.Set<TDb>().FindAsync(id);
            if (entity == null || (entity is ISoftDeletable softDeletable && softDeletable.IsDeleted))
                return null;
                
            return entity.Adapt<T>();
        }

        protected virtual IQueryable<TDb> AddFilter(IQueryable<TDb> query, TSearch search = null)
        {
            return query;
        }

        protected virtual IQueryable<TDb> AddInclude(IQueryable<TDb> query, TSearch search = null)
        {
            return query;
        }
    }
}