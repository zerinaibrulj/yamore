using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Service;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ServiceService : BaseCRUDService<Model.Service, ServiceSearchObject, Database.Service, ServiceInsertRequest, ServiceUpdateRequest, ServiceDeleteRequest>, IServiceService
    {
        private const string ServiceDeleteBlockedMessage =
            "This service cannot be deleted because it is still in use. "
            + "It is linked to one or more yacht add-ons and/or one or more reservations. Remove or update those links before deleting.";

        public ServiceService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        /// <inheritdoc />
        public string? GetDeleteBlockingErrorMessage(int serviceId)
        {
            var inYachts = Context.YachtServices.AsNoTracking().Any(ys => ys.ServiceId == serviceId);
            var inReservations = Context.ReservationServices.AsNoTracking().Any(rs => rs.ServiceId == serviceId);
            if (!inYachts && !inReservations) return null;
            return ServiceDeleteBlockedMessage;
        }

        public override Model.Service Delete(int id)
        {
            var err = GetDeleteBlockingErrorMessage(id);
            if (err != null) throw new UserException(err);
            return base.Delete(id);
        }

        public override IQueryable<Database.Service> AddFilter(ServiceSearchObject search, IQueryable<Database.Service> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.NameGTE))
            {
                filteredQuery = filteredQuery.Where(x => x.Name.StartsWith(search.NameGTE));
            }
            return filteredQuery;
        }
    }
}
