using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
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

        public async Task<int> SendWarningToUserAndOwnersAsync(int userId, string message, CancellationToken cancellationToken = default)
        {
            var text = message.Trim();
            if (text.Length > 255)
                text = text[..255];

            var now = DateTime.UtcNow;

            await using var tx = await Context.Database.BeginTransactionAsync(cancellationToken);
            var ownerIds = await Context.Reservations
                .Where(r => r.UserId == userId)
                .Where(r => (r.Status ?? "").ToLower() != "cancelled")
                .Select(r => r.Yacht.OwnerId)
                .Distinct()
                .ToListAsync(cancellationToken);

            var recipientIds = ownerIds.Append(userId).Distinct().ToList();

            foreach (var recipientId in recipientIds)
            {
                Context.Notifications.Add(new Database.Notification
                {
                    UserId = recipientId,
                    Message = text,
                    CreatedAt = now,
                    IsRead = false
                });
            }

            await Context.SaveChangesAsync(cancellationToken);
            await tx.CommitAsync(cancellationToken);
            return recipientIds.Count;
        }
    }
}
