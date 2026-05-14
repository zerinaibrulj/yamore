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
        private readonly IYachtsService _yachtsService;

        public WeatherForecastController(IWeatherForecastService service, IYachtsService yachtsService)
            : base(service)
        {
            _yachtsService = yachtsService;
        }

        [HttpPost]
        public override ActionResult<Model.WeatherForecast> Insert(WeatherForecastInsertRequest request)
        {
            if (!_yachtsService.CurrentUserMayManageRoute(request.RouteId))
                return Forbid();
            return base.Insert(request);
        }

        [HttpPut("{id}")]
        public override ActionResult<Model.WeatherForecast> Update(int id, WeatherForecastUpdateRequest request)
        {
            var existing = _service.GetById(id);
            if (existing == null)
                return NotFound();

            if (!_yachtsService.CurrentUserMayManageRoute(existing.RouteId)
                || !_yachtsService.CurrentUserMayManageRoute(request.RouteId))
                return Forbid();

            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        public override ActionResult<Model.WeatherForecast> Delete(int id)
        {
            var existing = _service.GetById(id);
            if (existing == null)
                return NotFound();

            if (!_yachtsService.CurrentUserMayManageRoute(existing.RouteId))
                return Forbid();

            return base.Delete(id);
        }
    }
}
