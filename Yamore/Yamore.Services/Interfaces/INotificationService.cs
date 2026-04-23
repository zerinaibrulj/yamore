using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Notification;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface INotificationService : ICRUDService<Model.Notification, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationDeleteRequest>
    {
        /// <summary>Notify the user and yacht owners involved in non-cancelled reservations.</summary>
        Task<int> SendWarningToUserAndOwnersAsync(int userId, string message, CancellationToken cancellationToken = default);

        /// <summary>Persist a single in-app notification (message truncated to 255 chars).</summary>
        void InsertUserNotification(int userId, string message);
    }
}
