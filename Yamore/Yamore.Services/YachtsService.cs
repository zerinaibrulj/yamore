using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;

namespace Yamore.Services
{
    public class YachtsService : IYachtsService
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
            },
            new Yachts()
            {
                YachtId=2,
                Name="Ocean Explorer",
                YearBuilt=2018,
                Length=45.0m,
                Capacity=12,
                PricePerDay=3000
            },
            new Yachts()
            {
                YachtId=3,
                Name="Sunset Cruiser",
                YearBuilt=2020,
                Length=25.0m,
                Capacity=6,
                PricePerDay=1200
            }
        };
        public List<Yachts> GetList()
        {
            return List;
        }
    }
}
