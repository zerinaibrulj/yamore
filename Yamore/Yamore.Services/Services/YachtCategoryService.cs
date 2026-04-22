using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class YachtCategoryService : BaseCRUDService<Model.YachtCategory, YachtCategorySearchObject, Database.YachtCategory, YachtCategoryInsertRequest, YachtCategoryUpdateRequest, YachtCategoryDeleteRequest>, IYachtCategoryService
    {
        private const string CategoryDeleteBlockedMessage =
            "This yacht category cannot be deleted because it is still in use. "
            + "One or more yachts are assigned to this category. Reassign or update those yachts to another category before deleting.";

        public YachtCategoryService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
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
            return base.Delete(id);
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
