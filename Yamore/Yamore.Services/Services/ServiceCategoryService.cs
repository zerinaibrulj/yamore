using System.Linq;
using MapsterMapper;
using Yamore.Model.Requests.ServiceCategory;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ServiceCategoryService : BaseCRUDService<Model.ServiceCategory, ServiceCategorySearchObject, Database.ServiceCategory, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest, ServiceCategoryDeleteRequest>, IServiceCategoryService
    {
        public ServiceCategoryService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.ServiceCategory> AddFilter(ServiceCategorySearchObject search, IQueryable<Database.ServiceCategory> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.Name))
                filteredQuery = filteredQuery.Where(x => x.Name.Contains(search.Name));

            return filteredQuery;
        }
    }
}
