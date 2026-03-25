using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;
using Yamore.Model.Requests.Notification;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class NotificationController : BaseCRUDController<Model.Notification, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationDeleteRequest>
    {
        private readonly _220245Context _context;

        public NotificationController(INotificationService service, _220245Context context) 
            : base(service)
        {
            _context = context;
        }

        public record WarningNotificationRequest(int UserId, string Message);

        /// <summary>
        /// Sends an admin warning to the user and to the owners of yachts that the user has reserved
        /// (non-cancelled reservations). This ensures both parties can read the warning.
        /// </summary>
        [HttpPost("warning-to-user-and-owners")]
        public async Task<ActionResult<object>> SendWarningToUserAndOwners([FromBody] WarningNotificationRequest request)
        {
            if (request.UserId <= 0) return BadRequest(new { message = "UserId is required." });
            if (string.IsNullOrWhiteSpace(request.Message))
                return BadRequest(new { message = "Message is required." });

            var message = request.Message.Trim();
            if (message.Length > 255) message = message[..255];

            var now = DateTime.UtcNow;

            // Distinct owners for yachts the user has reserved (excluding cancelled reservations).
            var ownerIds = await _context.Reservations
                .Where(r => r.UserId == request.UserId)
                .Where(r => (r.Status ?? "").ToLower() != "cancelled")
                .Select(r => r.Yacht.OwnerId)
                .Distinct()
                .ToListAsync();

            // Always include the user.
            var recipientIds = ownerIds.Append(request.UserId).Distinct().ToList();

            foreach (var recipientId in recipientIds)
            {
                _context.Notifications.Add(new Yamore.Services.Database.Notification
                {
                    UserId = recipientId,
                    Message = message,
                    CreatedAt = now,
                    IsRead = false
                });
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Warning sent.", recipients = recipientIds.Count });
        }
    }
}
