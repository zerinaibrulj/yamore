using System.Linq;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;
using Yamore.Model.Requests.ServiceCategory;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ServiceCategoryService : BaseCRUDService<Model.ServiceCategory, ServiceCategorySearchObject, Database.ServiceCategory, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest, ServiceCategoryDeleteRequest>, IServiceCategoryService
    {
        private const string ServiceCategoryDeleteBlockedMessage =
            "This service category cannot be deleted because it is still in use. "
            + "One or more services are assigned to this category. Reassign or update those services to another category before deleting.";

        public ServiceCategoryService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        /// <inheritdoc />
        public string? GetDeleteBlockingErrorMessage(int serviceCategoryId)
        {
            if (!Context.Services.AsNoTracking().Any(s => s.ServiceCategoryId == serviceCategoryId)) return null;
            return ServiceCategoryDeleteBlockedMessage;
        }

        public override Model.ServiceCategory Delete(int id)
        {
            var err = GetDeleteBlockingErrorMessage(id);
            if (err != null) throw new UserException(err);
            return base.Delete(id);
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
