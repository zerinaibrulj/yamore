using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Services.Database;

namespace Yamore.Services
{
    public class YachtsService : IYachtsService
    {
        public _220245Context Context { get; set; }

        public YachtsService(_220245Context context)
        {
            Context = context;
        }


        public virtual List<Model.Yachts> GetList()
        {
            var list = Context.Yachts.ToList();
            var result = new List<Model.Yachts>();
            list.ForEach(item =>
            {
                result.Add(new Model.Yachts()
                {
                    YachtId = item.YachtId,
                    Name = item.Name,
                    Capacity = item.Capacity,
                    Length = item.Length.Value,
                    PricePerDay = item.PricePerDay,
                    YearBuilt = item.YearBuilt.Value
                });
            });
            return result;
        }
    }
}
