using Microsoft.AspNetCore.Mvc.ModelBinding;
using Yamore.Model.SearchObjects;
using Yamore.Services;

namespace Yamore.API.Controllers
{
    public class BaseCRUDController<TModel, TSearch, TInsert, TUpdate> : BaseController<TModel, TSearch>
        where TSearch : BaseSearchObject
    {
        public BaseCRUDController(IService<TModel, TSearch> service) 
            : base(service)
        {
        }
    }
}
