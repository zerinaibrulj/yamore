using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services
{
    public interface IYachtsService : ICRUDService<Model.Yachts, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest>
    {
    }
}
