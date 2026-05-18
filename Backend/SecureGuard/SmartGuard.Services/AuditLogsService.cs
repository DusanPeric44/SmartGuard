using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;

using SmartGuard.Model.Requests;

namespace SmartGuard.Services
{
    public class AuditLogsService : BaseCRUDService<Model.DTOs.AuditLog, Database.AuditLog, AuditLogSearchObject, AuditLogInsertRequest, object>, IAuditLogsService
    {
        public AuditLogsService(SmartGuardContext context) : base(context)
        {
        }

        protected override IQueryable<Database.AuditLog> AddFilter(IQueryable<Database.AuditLog> query, AuditLogSearchObject search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.UserId))
            {
                var userId = search.UserId.Trim();
                query = query.Where(x => x.UserId == userId);
            }

            if (!string.IsNullOrWhiteSpace(search?.Action))
            {
                var action = search.Action.Trim();
                query = query.Where(x => x.Action.Contains(action));
            }

            if (!string.IsNullOrWhiteSpace(search?.Resource))
            {
                var resource = search.Resource.Trim();
                query = query.Where(x => x.Resource.Contains(resource));
            }

            if (!string.IsNullOrWhiteSpace(search?.Status))
            {
                var status = search.Status.Trim();
                query = query.Where(x => x.Status == status);
            }

            if (search?.From.HasValue == true)
            {
                query = query.Where(x => x.Timestamp >= search.From.Value);
            }

            if (search?.To.HasValue == true)
            {
                query = query.Where(x => x.Timestamp <= search.To.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.Text))
            {
                var text = search.Text.Trim();
                query = query.Where(x =>
                    x.Details.Contains(text) ||
                    x.Action.Contains(text) ||
                    x.Resource.Contains(text));
            }

            return query.OrderByDescending(x => x.Timestamp);
        }
    }
}
