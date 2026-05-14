using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.City;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CityController : BaseCRUDController<Model.City, CitySearchObject, CityInsertRequest, CityUpdateRequest, CityDeleteRequest>
    {
        private readonly ICityService _cityService;

        public CityController(ICityService service)
            : base(service)
        {
            _cityService = service;
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.City> Insert(CityInsertRequest request) => base.Insert(request);

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.City> Update(int id, CityUpdateRequest request) => base.Update(id, request);

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.City> Delete(int id)
        {
            var err = _cityService.GetDeleteBlockingErrorMessage(id);
            if (err != null) return RejectWithUserError(err);
            return base.Delete(id);
        }
    }
}
