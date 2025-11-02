using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.WeatherForecast;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IWeatherForecastService : ICRUDService<Model.WeatherForecast, WeatherForecastSearchObject, WeatherForecastInsertRequest, WeatherForecastUpdateRequest, WeatherForecastDeleteRequest>
    {
    }
}
