using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;
using Yamore.Model.Requests.Notification;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class NotificationService : BaseCRUDService<Model.Notification, NotificationSearchObject, Database.Notification, NotificationInsertRequest, NotificationUpdateRequest, NotificationDeleteRequest>, INotificationService
    {
        public NotificationService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override PagedResponse<Model.Notification> GetPaged(NotificationSearchObject search)
        {
            search ??= new NotificationSearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);

            var query = Context.Set<Database.Notification>().AsQueryable();
            query = AddFilter(search, query);
            query = query.OrderByDescending(x => x.CreatedAt ?? DateTime.MinValue);
            int count = query.Count();
            var list = query
                .Skip(search.Page!.Value * search.PageSize!.Value)
                .Take(search.PageSize.Value)
                .ToList();
            var result = Mapper.Map<List<Model.Notification>>(list);
            return new PagedResponse<Model.Notification> { Count = count, ResultList = result };
        }

        public override IQueryable<Database.Notification> AddFilter(NotificationSearchObject search, IQueryable<Database.Notification> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (search?.UserId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.UserId == search.UserId);
            }

            if (search?.IsRead != null)
            {
                filteredQurey = filteredQurey.Where(x => x.IsRead == search.IsRead);
            }

            return filteredQurey;
        }

        public async Task<int> SendWarningToUserAndOwnersAsync(
            int userId,
            string message,
            string? title = null,
            CancellationToken cancellationToken = default)
        {
            var text = message.Trim();
            if (text.Length > 1000)
                text = text[..1000];

            var t = (title ?? "Account notice").Trim();
            if (t.Length > 200)
                t = t[..200];

            var now = DateTime.UtcNow;

            await using var tx = await Context.Database.BeginTransactionAsync(cancellationToken);
            var ownerIds = await Context.Reservations
                .AsNoTracking()
                .Where(r => r.UserId == userId)
                // Matches ReservationStatuses.BlocksAvailability; inline for EF Core SQL translation.
                .Where(r => r.Status == null
                    || (r.Status != ReservationStatuses.Cancelled
                        && r.Status != ReservationStatuses.Completed))
                .Select(r => r.Yacht.OwnerId)
                .Distinct()
                .ToListAsync(cancellationToken);

            var recipientIds = ownerIds.Append(userId).Distinct().ToList();

            foreach (var recipientId in recipientIds)
            {
                Context.Notifications.Add(new Database.Notification
                {
                    UserId = recipientId,
                    Title = t,
                    Message = text,
                    CreatedAt = now,
                    IsRead = false
                });
            }

            await Context.SaveChangesAsync(cancellationToken);
            await tx.CommitAsync(cancellationToken);
            return recipientIds.Count;
        }

        public void InsertUserNotification(int userId, string title, string text)
        {
            var t = (title ?? string.Empty).Trim();
            if (t.Length > 200)
                t = t[..200];
            if (string.IsNullOrEmpty(t))
                t = "Yamore";

            var body = (text ?? string.Empty).Trim();
            if (body.Length > 1000)
                body = body[..1000];

            Context.Notifications.Add(new Database.Notification
            {
                UserId = userId,
                Title = t,
                Message = body,
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            });
            Context.SaveChanges();
        }

        public Model.Notification? MarkAsReadForUser(int notificationId, int userId)
        {
            var entity = Context.Notifications.FirstOrDefault(n => n.NotificationId == notificationId && n.UserId == userId);
            if (entity == null)
                return null;
            entity.IsRead = true;
            Context.SaveChanges();
            return Mapper.Map<Model.Notification>(entity);
        }
    }
}
