using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.WeatherForecast;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : BaseCRUDController<Model.WeatherForecast, WeatherForecastSearchObject, WeatherForecastInsertRequest, WeatherForecastUpdateRequest, WeatherForecastDeleteRequest>
    {
        public WeatherForecastController(IWeatherForecastService service)
            : base(service)
        {
        }
    }
}
