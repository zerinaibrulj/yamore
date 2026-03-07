using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.Requests.Yachts;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IYachtsService : ICRUDService<Yacht, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest, YachtsDeleteRequest>
    {
        public Yacht Activate(int id);
        public Yacht Hide(int id);
        public Yacht Edit(int id);
        public List<string> AllowedActions(int id);
        /// <summary>Recommended yachts for the user (by history) or popular yachts.</summary>
        PagedResponse<Yacht> GetRecommendations(int? userId, int page = 0, int pageSize = 10);
    }
}
