using System.Linq;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Yamore.Model;
using Yamore.Model.Requests.ServiceCategory;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class ServiceCategoryService : BaseCRUDService<Model.ServiceCategory, ServiceCategorySearchObject, Database.ServiceCategory, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest, ServiceCategoryDeleteRequest>, IServiceCategoryService
    {
        private const string ListCacheKey = "yamore:ServiceCategory:list:p0";
        private const string ServiceCategoryDeleteBlockedMessage =
            "This service category cannot be deleted because it is still in use. "
            + "One or more services are assigned to this category. Reassign or update those services to another category before deleting.";

        private readonly IMemoryCache _cache;

        public ServiceCategoryService(_220245Context context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper)
        {
            _cache = cache;
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
            var r = base.Delete(id);
            _cache.Remove(ListCacheKey);
            return r;
        }

        public override Model.ServiceCategory Insert(ServiceCategoryInsertRequest request)
        {
            var r = base.Insert(request);
            _cache.Remove(ListCacheKey);
            return r;
        }

        public override Model.ServiceCategory Update(int id, ServiceCategoryUpdateRequest request)
        {
            var r = base.Update(id, request);
            _cache.Remove(ListCacheKey);
            return r;
        }

        public override PagedResponse<Model.ServiceCategory> GetPaged(ServiceCategorySearchObject search)
        {
            search ??= new ServiceCategorySearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);
            var canCache = string.IsNullOrWhiteSpace(search.Name) && search.Page == 0;
            if (canCache && _cache.TryGetValue(ListCacheKey, out PagedResponse<Model.ServiceCategory>? cached) && cached != null)
                return cached;

            var result = base.GetPaged(search);
            if (canCache)
            {
                _cache.Set(
                    ListCacheKey,
                    result,
                    new MemoryCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5) });
            }

            return result;
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
