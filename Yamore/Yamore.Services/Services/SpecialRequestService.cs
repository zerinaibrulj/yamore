using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.SpecialRequest;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class SpecialRequestService : BaseCRUDService<Model.SpecialRequest, SpecialRequestSearchObject, Database.SpecialRequest, SpecialRequestInsertRequest, SpecialRequestUpdateRequest, SpecialRequestDeleteRequest>, ISpecialRequestService
    {
        public SpecialRequestService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.SpecialRequest> AddFilter(SpecialRequestSearchObject search, IQueryable<Database.SpecialRequest> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (search?.RequestId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.RequestId == search.RequestId);
            }

            if (search?.ReservationId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.ReservationId == search.ReservationId);
            }

            if (!string.IsNullOrWhiteSpace(search?.Description))
            {
                filteredQurey = filteredQurey.Where(x => x.Description.Contains(search.Description));
            }
            return filteredQurey;
        }
    }
}
