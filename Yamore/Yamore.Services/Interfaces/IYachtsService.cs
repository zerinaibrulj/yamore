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

        /// <summary>Creates a yacht for <see cref="YachtsAdminInsertRequest.OwnerId"/> (admin API only).</summary>
        Yacht InsertAsAdmin(YachtsAdminInsertRequest request);

        /// <summary>Updates a yacht including owner reassignment (admin API only).</summary>
        Yacht UpdateAsAdmin(int id, YachtsAdminUpdateRequest request);

        public List<string> AllowedActions(int id);
        /// <summary>Recommended yachts using reservation history, 4+ star review preferences, services, ratings, and popularity. Returns overview DTOs.</summary>
        PagedResponse<YachtOverviewDto> GetRecommendations(int? userId, int page = 0, int pageSize = 10);

        /// <summary>Admin overview of yachts with owner and location (city) names.</summary>
        PagedResponse<YachtOverviewDto> GetOverviewForAdmin(YachtsSearchObject search);

        /// <summary>Public / end-user listing: only yachts in <c>active</c> state.</summary>
        PagedResponse<YachtOverviewDto> GetOverviewForPublicListing(YachtsSearchObject search);

        /// <summary>Owner overview: returns yachts belonging to the given owner.</summary>
        PagedResponse<YachtOverviewDto> GetOverviewForOwner(int ownerId, YachtsSearchObject search);

        /// <summary>True if the current HTTP user is an administrator or owns the yacht (by <c>OwnerId</c>).</summary>
        bool CurrentUserMayManageYacht(int yachtId);

        /// <summary>True if the current HTTP user is an administrator or owns the yacht linked to the route.</summary>
        bool CurrentUserMayManageRoute(int routeId);

        /// <summary>True if a yacht row exists for <paramref name="yachtId"/> (for authorization checks before mutating).</summary>
        bool YachtExists(int yachtId);

        /// <summary>Occupied periods for calendar UI (all non-cancelled reservations + owner blocked availability).</summary>
        IReadOnlyList<YachtCalendarBlockDto> GetCalendarBlocks(int yachtId, int? excludeReservationId = null);
    }
}
