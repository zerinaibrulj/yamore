using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Service;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ServiceService : BaseCRUDService<Model.Service, ServiceSearchObject, Database.Service, ServiceInsertRequest, ServiceUpdateRequest, ServiceDeleteRequest>, IServiceService
    {
        public ServiceService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
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
