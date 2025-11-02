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
            var filteredQuery = base.AddFilter(search, query);

            if (search != null && search.ForecastId != 0)
            {
                filteredQuery = filteredQuery.Where(x => x.ForecastId == search.ForecastId);
            }

            if (search != null && search.RouteId != 0)
            {
                filteredQuery = filteredQuery.Where(x => x.RouteId == search.RouteId);
            }

            return filteredQuery;
        }
    }
}
