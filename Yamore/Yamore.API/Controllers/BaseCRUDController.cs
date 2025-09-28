using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Yamore.Model.SearchObjects;
using Yamore.Services;

namespace Yamore.API.Controllers
{
    public class BaseCRUDController<TModel, TSearch, TInsert, TUpdate> : BaseController<TModel, TSearch>
        where TModel : class
        where TSearch : BaseSearchObject
    {
        private IYachtCategoryService service;

        public BaseCRUDController(ICRUDService<TModel, TSearch, TInsert, TUpdate> service) 
            : base(service)
        {
        }


        [HttpPost]
        public TModel Insert(TInsert request)
        {
            return (_service as ICRUDService<TModel, TSearch, TInsert, TUpdate>).Insert(request);   //Uradit cemo kasting ICRUDService da bi imali pristup metodi Insert i Update
        }

        [HttpPut("{id}")]
        public TModel Update(int id, TUpdate request)
        {
            return (_service as ICRUDService<TModel, TSearch, TInsert, TUpdate>).Update(id, request);
        }
    }
}
