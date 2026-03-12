using Yamore.Model.Requests.YachtService;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IYachtServiceService : ICRUDService<Model.YachtService, YachtServiceSearchObject, YachtServiceInsertRequest, YachtServiceUpdateRequest, YachtServiceDeleteRequest>
    {
    }
}
