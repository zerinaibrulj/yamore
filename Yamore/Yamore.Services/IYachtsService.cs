using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services
{
    public interface IYachtsService
    {
        List<Yachts> GetList(YachtsSearchObject searchObject);
        Yachts Insert(YachtsInsertRequest request);
    }
}
