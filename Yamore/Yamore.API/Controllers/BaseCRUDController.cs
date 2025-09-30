using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    public class BaseCRUDController<TModel, TSearch, TInsert, TUpdate> : BaseController<TModel, TSearch>
        where TModel : class
        where TSearch : BaseSearchObject
    {
        protected new ICRUDService<TModel, TSearch, TInsert, TUpdate> _service;      //na ovaj nacin smo omogucili da imamo pristip insertu i update-u

        public BaseCRUDController(ICRUDService<TModel, TSearch, TInsert, TUpdate> service) 
            : base(service)
        {
            _service = service;                                                    //ovo moramo napisati obzirom da smo gore koristili kljucnu rijec NEW
        }


        [HttpPost]
        public TModel Insert(TInsert request)
        {
            return _service.Insert(request);   
        }

        [HttpPut("{id}")]
        public TModel Update(int id, TUpdate request)
        {
            return _service.Update(id, request);
        }
    }
}
