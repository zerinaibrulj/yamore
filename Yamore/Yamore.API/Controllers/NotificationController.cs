using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.Notification;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class NotificationController : BaseCRUDController<Model.Notification, NotificationSearchObject, NotificationInsertRequest, NotificationUpdateRequest, NotificationDeleteRequest>
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService service)
            : base(service)
        {
            _notificationService = service;
        }

        public record WarningNotificationRequest(int UserId, string Message);

        /// <summary>
        /// Sends an admin warning to the user and to the owners of yachts that the user has reserved
        /// (non-cancelled reservations). This ensures both parties can read the warning.
        /// </summary>
        [HttpPost("warning-to-user-and-owners")]
        public async Task<ActionResult<object>> SendWarningToUserAndOwners(
            [FromBody] WarningNotificationRequest request,
            CancellationToken cancellationToken)
        {
            if (request.UserId <= 0) return BadRequest(new { message = "UserId is required." });
            if (string.IsNullOrWhiteSpace(request.Message))
                return BadRequest(new { message = "Message is required." });

            var count = await _notificationService.SendWarningToUserAndOwnersAsync(
                request.UserId,
                request.Message,
                cancellationToken);
            return Ok(new { message = "Warning sent.", recipients = count });
        }
    }
}
