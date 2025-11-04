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
    }
}
