using MapsterMapper;
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
        public YachtCategoryService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
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
