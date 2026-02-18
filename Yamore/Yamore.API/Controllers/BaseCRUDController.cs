using Microsoft.AspNetCore.Mvc;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    public class BaseCRUDController<TModel, TSearch, TInsert, TUpdate, TDelete> : BaseController<TModel, TSearch>
        where TModel : class
        where TSearch : BaseSearchObject
    {
        protected new ICRUDService<TModel, TSearch, TInsert, TUpdate, TDelete> _service;      //na ovaj nacin smo omogucili da imamo pristip insertu i update-u

        public BaseCRUDController(ICRUDService<TModel, TSearch, TInsert, TUpdate, TDelete> service) 
            : base(service)
        {
            _service = service;                                                    //ovo moramo napisati obzirom da smo gore koristili kljucnu rijec NEW
        }


        [HttpPost]
        public virtual ActionResult<TModel> Insert(TInsert request)
        {
            var result = _service.Insert(request);
            Response.Headers["X-Operation-Message"] = $"{typeof(TModel).Name} created successfully.";
            return Ok(result);
        }

        [HttpPut("{id}")]
        public virtual ActionResult<TModel> Update(int id, TUpdate request)
        {
            var result = _service.Update(id, request);
            Response.Headers["X-Operation-Message"] = $"{typeof(TModel).Name} updated successfully.";
            return Ok(result);
        }

        [HttpDelete("{id}")]
        public virtual ActionResult<TModel> Delete(int id)
        {
            var result = _service.Delete(id);
            Response.Headers["X-Operation-Message"] = $"{typeof(TModel).Name} deleted successfully.";
            return Ok(result);
        }
    }
}
