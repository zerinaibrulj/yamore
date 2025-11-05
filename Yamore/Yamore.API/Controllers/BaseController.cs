using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Linq.Dynamic.Core;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]


    public class BaseController<TModel, TSearch> : ControllerBase 
        where TModel : class
        where TSearch : BaseSearchObject
    {
        protected IService<TModel, TSearch> _service;

        public BaseController(IService<TModel, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public virtual PagedResponse<TModel> GetPaged([FromQuery] TSearch search)
        {
            return _service.GetPaged(search);
        }


        [HttpGet("{id}")]
        public virtual TModel GetById(int id)
        {
            return _service.GetById(id);
        }
    }
}
