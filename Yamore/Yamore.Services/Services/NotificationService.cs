using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
    }
}
