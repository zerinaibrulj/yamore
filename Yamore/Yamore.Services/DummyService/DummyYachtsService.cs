using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.Services.DummyService
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

        public Yachts GetById(int id)
        {
            throw new NotImplementedException();
        }

        public List<Yachts> GetList(YachtsSearchObject searchObject)
        {
            return List;
        }

        public PagedResponse<Yachts> GetPaged(YachtsSearchObject search)
        {
            throw new NotImplementedException();
        }

        public Yachts Insert(YachtsInsertRequest request)
        {
            throw new NotImplementedException();
        }

        public Yachts Update(int id, YachtsUpdateRequest request)
        {
            throw new NotImplementedException();
        }
    }
}
