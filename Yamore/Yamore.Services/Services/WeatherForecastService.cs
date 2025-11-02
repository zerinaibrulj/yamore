using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.WeatherForecast;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class WeatherForecastService : BaseCRUDService<Model.WeatherForecast, WeatherForecastSearchObject, Database.WeatherForecast, WeatherForecastInsertRequest, WeatherForecastUpdateRequest, WeatherForecastDeleteRequest>, IWeatherForecastService
    {
        public WeatherForecastService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.WeatherForecast> AddFilter(WeatherForecastSearchObject search, IQueryable<Database.WeatherForecast> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (search?.ForecastId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.ForecastId == search.ForecastId);
            }

            if (search?.RouteId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.RouteId == search.RouteId);
            }

            return filteredQurey;
        }
    }
}
