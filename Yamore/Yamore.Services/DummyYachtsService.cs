using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;

namespace Yamore.Services
{
    public class DummyYachtsService : YachtsService
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
        public override List<Yachts> GetList()
        {
            return List;
        }
    }
}
