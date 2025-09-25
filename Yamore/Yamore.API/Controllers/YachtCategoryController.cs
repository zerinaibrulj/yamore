using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtCategoryController : ControllerBase
    {
        protected IYachtCategoryService _service;

        public YachtCategoryController(IYachtCategoryService service)
        {
            _service = service;
        }

        [HttpGet]
        public List<Model.YachtCategory> GetList([FromQuery] YachtCategorySearchObject searchObject)
        {
            return _service.GetList(searchObject);
        }


        [HttpPost]
        public YachtCategory Insert(YachtCategoryInsertRequest request)
        {
            return _service.Insert(request);
        }


        [HttpPut("{id}")]
        public YachtCategory Update(int id, YachtCategoryUpdateRequest request)
        {
            return _service.Update(id, request);
        }
    }
}
