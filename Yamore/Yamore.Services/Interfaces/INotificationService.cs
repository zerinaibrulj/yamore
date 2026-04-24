using System.Threading;
using System.Threading.Tasks;
using Yamore.Model.Requests.Notification;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface INotificationService : ICRUDService<Model.Notification, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationDeleteRequest>
    {
        /// <summary>Notify the user and yacht owners involved in non-cancelled reservations.</summary>
        Task<int> SendWarningToUserAndOwnersAsync(int userId, string message, string? title = null, CancellationToken cancellationToken = default);

        void InsertUserNotification(int userId, string title, string text);

        /// <summary>Sets <c>IsRead = true</c> if the notification exists and belongs to the user.</summary>
        Model.Notification? MarkAsReadForUser(int notificationId, int userId);
    }
}
