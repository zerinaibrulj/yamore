using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.ReservationService;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ReservationServiceService : BaseCRUDService<Model.ReservationService, ReservationServiceSearchObject, Database.ReservationService, ReservationServiceInsertRequest, ReservationServiceUpdateRequest, ReservationServiceDeleteRequest>, IReservationServiceService
    {
        public ReservationServiceService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.ReservationService> AddFilter(ReservationServiceSearchObject search, IQueryable<Database.ReservationService> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (search?.ReservationServicesId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.ReservationServicesId == search.ReservationServicesId);
            }

            if (search?.ReservationId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.ReservationId == search.ReservationId);
            }

            if (search?.ServiceId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.ServiceId == search.ServiceId);
            }

            return filteredQurey;
        }
    }
}
