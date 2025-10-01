using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{

    [ApiController]
    [Route("[controller]")]
    public class CountryController : BaseCRUDController<Model.Country, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest>
    {
        public CountryController(ICountryService service)
            : base(service)
        {
        }
    }
}
