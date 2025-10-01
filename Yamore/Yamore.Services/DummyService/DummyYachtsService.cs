using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Yachts;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.Services.DummyService
{
    public class DummyYachtsService : IYachtsService
    {
        public List<Yacht> List = new List<Yacht>()
        {
            new Yacht()
            {
                YachtId=1,
                Name ="Sea Breeze",
                YearBuilt=2015,
                Length=30.5m,
                Capacity=8,
                PricePerDay=1500
            }
        };

        public Yacht Delete(int id)
        {
            throw new NotImplementedException();
        }

        public Yacht GetById(int id)
        {
            throw new NotImplementedException();
        }

        public List<Yacht> GetList(YachtsSearchObject searchObject)
        {
            return List;
        }

        public PagedResponse<Yacht> GetPaged(YachtsSearchObject search)
        {
            throw new NotImplementedException();
        }

        public Yacht Insert(YachtsInsertRequest request)
        {
            throw new NotImplementedException();
        }

        public Yacht Update(int id, YachtsUpdateRequest request)
        {
            throw new NotImplementedException();
        }
    }
}
