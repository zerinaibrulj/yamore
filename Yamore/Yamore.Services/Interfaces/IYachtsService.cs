using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IYachtsService : ICRUDService<Yachts, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest>
    {
    }
}
