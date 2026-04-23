using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using System.Linq;
using System.Linq.Dynamic.Core;
using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class YachtCategoryService : BaseCRUDService<Model.YachtCategory, YachtCategorySearchObject, Database.YachtCategory, YachtCategoryInsertRequest, YachtCategoryUpdateRequest, YachtCategoryDeleteRequest>, IYachtCategoryService
    {
        private const string CategoryListCacheKey = "yamore:YachtCategory:list:p0";
        private const string CategoryDeleteBlockedMessage =
            "This yacht category cannot be deleted because it is still in use. "
            + "One or more yachts are assigned to this category. Reassign or update those yachts to another category before deleting.";

        private readonly IMemoryCache _cache;

        public YachtCategoryService(_220245Context context, IMapper mapper, IMemoryCache cache)
            : base(context, mapper)
        {
            _cache = cache;
        }

        /// <inheritdoc />
        public string? GetDeleteBlockingErrorMessage(int categoryId)
        {
            if (!Context.Yachts.AsNoTracking().Any(y => y.CategoryId == categoryId)) return null;
            return CategoryDeleteBlockedMessage;
        }

        public override Model.YachtCategory Delete(int id)
        {
            var err = GetDeleteBlockingErrorMessage(id);
            if (err != null) throw new UserException(err);
            var r = base.Delete(id);
            _cache.Remove(CategoryListCacheKey);
            return r;
        }

        public override Model.YachtCategory Insert(YachtCategoryInsertRequest request)
        {
            var r = base.Insert(request);
            _cache.Remove(CategoryListCacheKey);
            return r;
        }

        public override Model.YachtCategory Update(int id, YachtCategoryUpdateRequest request)
        {
            var r = base.Update(id, request);
            _cache.Remove(CategoryListCacheKey);
            return r;
        }

        public override PagedResponse<Model.YachtCategory> GetPaged(YachtCategorySearchObject search)
        {
            search ??= new YachtCategorySearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);
            var canCache = string.IsNullOrWhiteSpace(search.NameGTE) && search.Page == 0;
            if (canCache && _cache.TryGetValue(CategoryListCacheKey, out PagedResponse<Model.YachtCategory>? cached) && cached != null)
                return cached;

            var result = base.GetPaged(search);
            if (canCache)
            {
                _cache.Set(
                    CategoryListCacheKey,
                    result,
                    new MemoryCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5) });
            }

            return result;
        }

        public override IQueryable<Database.YachtCategory> AddFilter(YachtCategorySearchObject search, IQueryable<Database.YachtCategory> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.NameGTE))
            {
                filteredQurey = filteredQurey.Where(x => x.Name.StartsWith(search.NameGTE));
            }
            return filteredQurey;
        }
    }
}
