using Yamore.Model;
using Yamore.Model.Requests.YachtAvailability;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IYachtAvailabilityService : ICRUDService<YachtAvailability, YachtAvailabilitySearchObject, YachtAvailabilityInsertRequest, YachtAvailabilityUpdateRequest, YachtAvailabilityDeleteRequest>
    {
    }
}
