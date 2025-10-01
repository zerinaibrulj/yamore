using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IYachtsService : ICRUDService<Yacht, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest, YachtCategoryDeleteRequest>
    {
    }
}
