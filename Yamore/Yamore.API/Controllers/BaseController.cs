using Microsoft.AspNetCore.Mvc;
using System.Linq.Dynamic.Core;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class BaseController<TModel, TSearch> : ControllerBase 
        where TSearch : BaseSearchObject
    {
        protected IService<TModel, TSearch> _service;

        public BaseController(IService<TModel, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public PagedResult<TModel> GetList([FromQuery] TSearch search)
        {
            return _service.GetPaged(search);
        }


        [HttpGet("{id}")]
        public TModel GetById(int id)
        {
            return _service.GetById(id);
        }



        //[HttpPost]
        //public User Insert(UserInsertRequest request)
        //{
        //    return _service.Insert(request);
        //}


        //[HttpPut("{id}")]
        //public User Update(int id, UserUpdateRequest request)
        //{
        //    return _service.Update(id, request);
        //}
    }
}
