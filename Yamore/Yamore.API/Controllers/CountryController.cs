using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.Country;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{

    [ApiController]
    [Route("[controller]")]
    public class CountryController : BaseCRUDController<Model.Country, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest, CountryDeleteRequest>
    {
        private readonly ICountryService _countryService;

        public CountryController(ICountryService service)
            : base(service)
        {
            _countryService = service;
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.Country> Insert(CountryInsertRequest request) => base.Insert(request);

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.Country> Update(int id, CountryUpdateRequest request) => base.Update(id, request);

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.Country> Delete(int id)
        {
            var err = _countryService.GetDeleteBlockingErrorMessage(id);
            if (err != null) return RejectWithUserError(err);
            return base.Delete(id);
        }
    }
}
