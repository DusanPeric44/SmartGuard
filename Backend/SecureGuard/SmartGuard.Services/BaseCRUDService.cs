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
    public abstract class BaseCRUDService<T, TDb, TSearch, TInsert, TUpdate> : BaseGetService<T, TDb, TSearch>, IBaseCRUDService<T, TSearch, TInsert, TUpdate> 
        where T : class 
        where TDb : class 
        where TSearch : BaseSearchObject 
        where TInsert : class 
        where TUpdate : class
    {
        public BaseCRUDService(SmartGuardContext context) : base(context)
        {
        }

        public virtual async Task<T> InsertAsync(TInsert insert)
        {
            var entity = insert.Adapt<TDb>();
            _context.Set<TDb>().Add(entity);
            await _context.SaveChangesAsync();
            return entity.Adapt<T>();
        }

        public virtual async Task<T> UpdateAsync(int id, TUpdate update)
        {
            var entity = await _context.Set<TDb>().FindAsync(id);
            if (entity == null)
                return null;
                
            update.Adapt(entity);
            await _context.SaveChangesAsync();
            return entity.Adapt<T>();
        }

        public virtual async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Set<TDb>().FindAsync(id);
            if (entity == null)
                return false;

            if (entity is ISoftDeletable softDeletable)
            {
                softDeletable.IsDeleted = true;
            }
            else
            {
                _context.Set<TDb>().Remove(entity);
            }

            await _context.SaveChangesAsync();
            return true;
        }
    }
}