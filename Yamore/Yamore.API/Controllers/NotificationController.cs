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
        public NotificationController(INotificationService service) 
            : base(service)
        {
        }
    }
}
