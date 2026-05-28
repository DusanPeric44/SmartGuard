using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Model;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Notifications.Microservice.Database;
using SmartGuard.Notifications.Microservice.Services;

namespace SmartGuard.Notifications.Microservice.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationsController(
        NotificationsDbContext dbContext,
        IUserContext userContext,
        INotificationsRealtimePublisher realtimePublisher) : ControllerBase
    {
        [HttpGet("{id:int}")]
        public async Task<ActionResult<Notification>> GetById(int id, CancellationToken cancellationToken)
        {
            var userId = userContext.UserId;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var entity = await dbContext.Notifications.AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, cancellationToken);

            if (entity == null)
            {
                return NotFound();
            }

            return new Notification
            {
                Id = entity.Id,
                UserId = entity.UserId,
                Title = entity.Title,
                Text = entity.Text,
                Timestamp = entity.Timestamp,
                IsRead = entity.IsRead
            };
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<Notification>>> Get(
            [FromQuery] int? page,
            [FromQuery] int? pageSize,
            [FromQuery] bool? isRead,
            CancellationToken cancellationToken)
        {
            var userId = userContext.UserId;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var query = dbContext.Notifications.AsNoTracking()
                .Where(x => x.UserId == userId);

            if (isRead != null)
            {
                query = query.Where(x => x.IsRead == isRead);
            }

            var count = await query.CountAsync(cancellationToken);

            var p = page.GetValueOrDefault(1);
            var ps = pageSize.GetValueOrDefault(20);
            if (p < 1) p = 1;
            if (ps < 1) ps = 1;
            if (ps > 200) ps = 200;

            var result = await query
                .OrderByDescending(x => x.Timestamp)
                .Skip((p - 1) * ps)
                .Take(ps)
                .Select(x => new Notification
                {
                    Id = x.Id,
                    UserId = x.UserId,
                    Title = x.Title,
                    Text = x.Text,
                    Timestamp = x.Timestamp,
                    IsRead = x.IsRead
                })
                .ToListAsync(cancellationToken);

            return new PagedResult<Notification>
            {
                Count = count,
                Result = result
            };
        }

        [HttpPatch("{id:int}/read")]
        public async Task<IActionResult> MarkAsRead(int id, CancellationToken cancellationToken)
        {
            var userId = userContext.UserId;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var entity = await dbContext.Notifications
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, cancellationToken);

            if (entity == null)
            {
                return NotFound();
            }

            if (!entity.IsRead)
            {
                entity.IsRead = true;
                await dbContext.SaveChangesAsync(cancellationToken);
                await realtimePublisher.SendUnreadCountAsync(userId, force: false, cancellationToken);
            }

            return NoContent();
        }

        [HttpPost("read-all")]
        public async Task<IActionResult> MarkAllAsRead(CancellationToken cancellationToken)
        {
            var userId = userContext.UserId;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Unauthorized();
            }

            var notifications = await dbContext.Notifications
                .Where(x => x.UserId == userId && !x.IsRead)
                .ToListAsync(cancellationToken);

            foreach (var n in notifications)
            {
                n.IsRead = true;
            }

            if (notifications.Count > 0)
            {
                await dbContext.SaveChangesAsync(cancellationToken);
                await realtimePublisher.SendUnreadCountAsync(userId, force: false, cancellationToken);
            }

            return Ok(new { marked = notifications.Count });
        }
    }
}

