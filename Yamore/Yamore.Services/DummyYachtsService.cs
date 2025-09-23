using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.SearchObjects;

namespace Yamore.Services
{
    public class DummyYachtsService : IYachtsService
    {
        public List<Yachts> List = new List<Yachts>()
        {
            new Yachts()
            {
                YachtId=1,
                Name ="Sea Breeze",
                YearBuilt=2015,
                Length=30.5m,
                Capacity=8,
                PricePerDay=1500
            }
        };
        public List<Yachts> GetList(YachtsSearchObject searchObject)
        {
            return List;
        }
    }
}
