using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Yachts;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using System.Linq.Dynamic.Core;
using Yamore.Services.YachtStateMachine;

namespace Yamore.Services.Services
{
    public class YachtsService : BaseCRUDService<Model.Yacht, YachtsSearchObject, Database.Yacht, YachtsInsertRequest, YachtsUpdateRequest, YachtsDeleteRequest>, IYachtsService
    {
        public BaseYachtState BaseYachtState { get; set; }

        public YachtsService(_220245Context context, IMapper mapper, BaseYachtState baseYachtState) 
            : base(context, mapper)
        {
            BaseYachtState = baseYachtState;
        }



        public override IQueryable<Database.Yacht> AddFilter(YachtsSearchObject search, IQueryable<Database.Yacht> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.NameGTE))
            {
                filteredQurey = filteredQurey.Where(x => x.Name.StartsWith(search.NameGTE));
            }

            if(search?.YearBuilt != null)
            {
                filteredQurey = filteredQurey.Where(x => x.YearBuilt == search.YearBuilt);
            }

            if(search?.Capacity != null)
            {
                filteredQurey = filteredQurey.Where(x => x.Capacity == search.Capacity);
            }

            if(search?.PricePerDay != null)
            {
                filteredQurey = filteredQurey.Where(x => x.PricePerDay == search.PricePerDay);
            }

            if (!string.IsNullOrWhiteSpace(search?.OrderBy))
            {
                var item = search.OrderBy.Split(' ');
                if (item.Length > 2 || item.Length == 0)
                {
                    throw new ApplicationException("You can only sort by one field!");
                }
                if (item.Length == 1)
                {
                    filteredQurey = filteredQurey.OrderBy(search.OrderBy);
                }
                else
                {
                    filteredQurey = filteredQurey.OrderBy($"{item[0]} {item[1]}");
                }
            }

            return filteredQurey;
        }



        public override Model.Yacht Insert(YachtsInsertRequest request)
        {
            var state = BaseYachtState.CreateState("initial");
            return state.Insert(request);
        }
    }
}
