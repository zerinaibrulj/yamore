using Azure.Core;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Yachts;
using Yamore.Services;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using Yamore.Services.YachtStateMachine;

namespace Yamore.Services.Services
{
    public class YachtsService : BaseCRUDService<Model.Yacht, YachtsSearchObject, Database.Yacht, YachtsInsertRequest, YachtsUpdateRequest, YachtsDeleteRequest>, IYachtsService
    {
        public BaseYachtState BaseYachtState { get; set; }

        private readonly IHttpContextAccessor? _httpContextAccessor;
        private readonly IYachtDocumentService _yachtDocumentService;

        public YachtsService(
            _220245Context context,
            IMapper mapper,
            BaseYachtState baseYachtState,
            IYachtDocumentService yachtDocumentService,
            IHttpContextAccessor? httpContextAccessor = null)
            : base(context, mapper)
        {
            BaseYachtState = baseYachtState;
            _yachtDocumentService = yachtDocumentService;
            _httpContextAccessor = httpContextAccessor;
        }

        private static bool IsDraftState(string? stateMachine) =>
            string.IsNullOrWhiteSpace(stateMachine)
            || string.Equals(stateMachine.Trim(), YachtStateNames.Draft, StringComparison.OrdinalIgnoreCase);

        private bool CanPublishYacht(Database.Yacht yacht) =>
            IsDraftState(yacht.StateMachine)
            && _yachtDocumentService.AreMandatoryDocumentsApproved(yacht.YachtId);

        /// <summary>Load yacht for state transitions and owner/admin updates (no public visibility filter).</summary>
        private Model.Yacht? LoadYachtUnrestricted(int id)
        {
            var entity = Context.Set<Database.Yacht>().Find(id);
            if (entity == null) return null;
            return Mapper.Map<Model.Yacht>(entity);
        }

        /// <summary>
        /// End users only see <c>active</c> yachts. Admins see any; owners see their own in any state.
        /// </summary>
        public override Model.Yacht GetById(int id)
        {
            var y = LoadYachtUnrestricted(id);
            if (y == null) return null;
            var http = _httpContextAccessor?.HttpContext;
            if (http == null)
            {
                return string.Equals(y.StateMachine, YachtStateNames.Active, StringComparison.OrdinalIgnoreCase) ? y : null;
            }

            if (http.User?.IsInRole(AppRoles.Admin) == true) return y;
            if (int.TryParse(http.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var userId) &&
                y.OwnerId == userId)
            {
                return y;
            }

            return string.Equals(y.StateMachine, YachtStateNames.Active, StringComparison.OrdinalIgnoreCase) ? y : null;
        }

        /// <summary>
        /// Non-admins only receive yachts in <c>active</c> state (same rule as the public catalog).
        /// </summary>
        public override PagedResponse<Model.Yacht> GetPaged(YachtsSearchObject search)
        {
            search ??= new YachtsSearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);
            if (_httpContextAccessor?.HttpContext?.User?.IsInRole(AppRoles.Admin) == true)
                return base.GetPaged(search);

            var query = Context.Set<Database.Yacht>().AsQueryable()
                .Where(y => y.StateMachine == YachtStateNames.Active);
            query = AddFilter(search, query);
            var count = query.Count();
            query = query.Skip(search.Page!.Value * search.PageSize!.Value).Take(search.PageSize.Value);

            var list = query.ToList();
            var result = new List<Model.Yacht>();
            result = Mapper.Map(list, result);
            return new PagedResponse<Model.Yacht> { Count = count, ResultList = result };
        }

        public override IQueryable<Database.Yacht> AddFilter(YachtsSearchObject search, IQueryable<Database.Yacht> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.NameGTE))
            {
                filteredQurey = filteredQurey.Where(x => x.Name.StartsWith(search.NameGTE));
            }

            if (search?.YearBuilt != null)
            {
                filteredQurey = filteredQurey.Where(x => x.YearBuilt == search.YearBuilt);
            }

            if (search?.Capacity != null)
            {
                filteredQurey = filteredQurey.Where(x => x.Capacity == search.Capacity);
            }

            if (search?.CapacityMin != null)
            {
                filteredQurey = filteredQurey.Where(x => x.Capacity >= search.CapacityMin);
            }

            if (search?.CapacityMax != null)
            {
                filteredQurey = filteredQurey.Where(x => x.Capacity <= search.CapacityMax);
            }

            if (search?.PricePerDay != null)
            {
                filteredQurey = filteredQurey.Where(x => x.PricePerDay == search.PricePerDay);
            }

            if (search?.PricePerDayMin != null)
            {
                filteredQurey = filteredQurey.Where(x => x.PricePerDay >= search.PricePerDayMin);
            }

            if (search?.PricePerDayMax != null)
            {
                filteredQurey = filteredQurey.Where(x => x.PricePerDay <= search.PricePerDayMax);
            }

            if (search?.LocationId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.LocationId == search.LocationId);
            }

            if (search?.CityId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.LocationId == search.CityId);
            }

            if (search?.CountryId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.Location != null && x.Location.CountryId == search.CountryId);
            }

            if (search?.AvailableFrom != null && search?.AvailableTo != null)
            {
                var from = search.AvailableFrom.Value;
                var to = search.AvailableTo.Value;
                filteredQurey = filteredQurey.Where(y =>
                    !Context.Reservations.Any(r => r.YachtId == y.YachtId && r.StartDate < to && r.EndDate > from
                        && r.Status != ReservationStatuses.Cancelled
                        && r.Status != ReservationStatuses.Completed) &&
                    !Context.YachtAvailabilities.Any(a => a.YachtId == y.YachtId && a.IsBlocked && a.StartDate < to && a.EndDate > from));
            }

            if (!string.IsNullOrWhiteSpace(search?.OrderBy))
            {
                var orderExpression = DynamicOrderByGuard.BuildYachtOrderExpression(search.OrderBy);
                filteredQurey = filteredQurey.OrderBy(orderExpression);
            }

            return filteredQurey;
        }



        public override Model.Yacht Insert(YachtsInsertRequest request)
        {
            var http = _httpContextAccessor?.HttpContext;
            if (http?.User?.IsInRole(AppRoles.Admin) == true)
            {
                throw new UserException(
                    "Administrators must create yachts using POST /Yachts/admin with an explicit owner assignment.");
            }

            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var ownerId))
                throw new ForbiddenException("You must be signed in to create a yacht.");

            var state = BaseYachtState.CreateState(YachtStateNames.Initial);
            return state.Insert(request, ownerId);
        }

        public Model.Yacht InsertAsAdmin(YachtsAdminInsertRequest request)
        {
            var http = _httpContextAccessor?.HttpContext;
            if (http?.User?.IsInRole(AppRoles.Admin) != true)
                throw new ForbiddenException("Only administrators may create yachts on behalf of another owner.");

            if (!Context.Users.AsNoTracking().Any(u => u.UserId == request.OwnerId))
                throw new UserException("The specified owner user was not found.");

            var state = BaseYachtState.CreateState(YachtStateNames.Initial);
            return state.Insert(request, request.OwnerId);
        }

        public Model.Yacht UpdateAsAdmin(int id, YachtsAdminUpdateRequest request)
        {
            var http = _httpContextAccessor?.HttpContext;
            if (http?.User?.IsInRole(AppRoles.Admin) != true)
                throw new ForbiddenException("Only administrators may reassign yacht ownership through this endpoint.");

            if (!Context.Users.AsNoTracking().Any(u => u.UserId == request.OwnerId))
                throw new UserException("The specified owner user was not found.");

            var entity = LoadYachtUnrestricted(id)
                ?? throw new NotFoundException($"Yacht with id {id} not found.");
            var state = BaseYachtState.CreateState(entity.StateMachine ?? YachtStateNames.Draft);
            return state.Update(id, request);
        }

        public override Model.Yacht Update(int id, YachtsUpdateRequest request)
        {
            var entity = LoadYachtUnrestricted(id)
                ?? throw new NotFoundException($"Yacht with id {id} not found.");
            if (!CurrentUserMayManageYacht(id))
                throw new ForbiddenException("You may only update yachts that you own.");
            var state = BaseYachtState.CreateState(entity.StateMachine ?? YachtStateNames.Draft);
            return state.Update(id, request);
        }

        public Model.Yacht Activate(int id)
        {
            var entity = Context.Set<Database.Yacht>().Find(id)
                ?? throw new NotFoundException($"Yacht with id {id} not found.");
            if (!CurrentUserMayManageYacht(id))
                throw new ForbiddenException("You may only change the listing state for yachts that you own.");
            if (!IsDraftState(entity.StateMachine))
            {
                throw new UserException(
                    "Only yachts in Draft state can be published. Use Hide or Edit for other states.");
            }

            if (!_yachtDocumentService.AreMandatoryDocumentsApproved(id))
            {
                throw new UserException(
                    "This yacht cannot be published until Registration, Insurance, and Safety Certificate documents are uploaded and approved by an administrator.");
            }

            var state = BaseYachtState.CreateState(entity.StateMachine);
            return state.Activate(id);
        }

        public Model.Yacht Hide(int id)
        {
            var entity = LoadYachtUnrestricted(id)
                ?? throw new NotFoundException($"Yacht with id {id} not found.");
            if (!CurrentUserMayManageYacht(id))
                throw new ForbiddenException("You may only change the listing state for yachts that you own.");
            var state = BaseYachtState.CreateState(entity.StateMachine ?? YachtStateNames.Draft);
            return state.Hide(id);
        }

        public Model.Yacht Edit(int id)
        {
            var entity = LoadYachtUnrestricted(id)
                ?? throw new NotFoundException($"Yacht with id {id} not found.");
            if (!CurrentUserMayManageYacht(id))
                throw new ForbiddenException("You may only change the listing state for yachts that you own.");
            var state = BaseYachtState.CreateState(entity.StateMachine ?? YachtStateNames.Draft);
            return state.Edit(id);
        }

        public List<string> AllowedActions(int id)
        {
            if (id <= 0)
            {
                var state = BaseYachtState.CreateState(YachtStateNames.Initial);
                return state.AllowedActions(null);
            }
            else
            {
                var entity = Context.Yachts.Find(id);
                if (entity == null)
                {
                    var s = BaseYachtState.CreateState(YachtStateNames.Initial);
                    return s.AllowedActions(null);
                }

                if (!CurrentUserMayManageYacht(id))
                    return new List<string>();

                var state = BaseYachtState.CreateState(entity.StateMachine ?? YachtStateNames.Draft);
                return state.AllowedActions(entity);
            }
        }

        /// <summary>
        /// Recommendation: content-based signals from past reservations and from yachts the user rated 4+ (category, location, country),
        /// plus add-on service history, then average community rating and booking popularity. Returns overview DTOs with explanations.
        /// </summary>
        public PagedResponse<YachtOverviewDto> GetRecommendations(int? userId, int page = 0, int pageSize = 10)
        {
            page = PagingConstraints.NormalizePage(page);
            pageSize = PagingConstraints.NormalizePageSize(pageSize);

            var activeYachts = Context.Yachts
                .Include(y => y.Owner)
                .Include(y => y.Category)
                .Include(y => y.Location).ThenInclude(c => c.Country)
                .Include(y => y.Reviews)
                .Include(y => y.YachtServices).ThenInclude(ys => ys.Service)
                .Include(y => y.Reservations)
                .Where(y => y.StateMachine == "active")
                .AsQueryable();

            IOrderedQueryable<Database.Yacht> ordered;
            RecommendationSignals? signals = null;

            if (userId.HasValue)
            {
                var userReservationYachtIds = Context.Reservations
                    .Where(r => r.UserId == userId && r.Status != "Cancelled")
                    .Select(r => r.YachtId).Distinct().ToList();

                var highlyRatedYachtIds = Context.Reviews
                    .Where(r => r.UserId == userId && r.Rating >= 4)
                    .Select(r => r.YachtId).Distinct().ToList();

                List<int> categoryIdsFromHighRatings;
                List<int> locationIdsFromHighRatings;
                List<int> countryIdsFromHighRatings;
                if (highlyRatedYachtIds.Count == 0)
                {
                    categoryIdsFromHighRatings = new List<int>();
                    locationIdsFromHighRatings = new List<int>();
                    countryIdsFromHighRatings = new List<int>();
                }
                else
                {
                    var likedYachts = Context.Yachts
                        .AsNoTracking()
                        .Where(y => highlyRatedYachtIds.Contains(y.YachtId));
                    categoryIdsFromHighRatings = likedYachts.Select(y => y.CategoryId).Distinct().ToList();
                    locationIdsFromHighRatings = likedYachts.Select(y => y.LocationId).Distinct().ToList();
                    countryIdsFromHighRatings = likedYachts
                        .Where(y => y.Location != null)
                        .Select(y => y.Location!.CountryId)
                        .Distinct()
                        .ToList();
                }

                var preferredCategoryIds = Context.Yachts
                    .AsNoTracking()
                    .Where(y => userReservationYachtIds.Contains(y.YachtId))
                    .Select(y => y.CategoryId)
                    .Distinct()
                    .ToList();
                var preferredLocationIds = Context.Yachts
                    .AsNoTracking()
                    .Where(y => userReservationYachtIds.Contains(y.YachtId))
                    .Select(y => y.LocationId)
                    .Distinct()
                    .ToList();
                var preferredCountryIds = Context.Yachts
                    .AsNoTracking()
                    .Where(y => userReservationYachtIds.Contains(y.YachtId) && y.Location != null)
                    .Select(y => y.Location!.CountryId)
                    .Distinct()
                    .ToList();

                var combinedCategoryIds = preferredCategoryIds.Union(categoryIdsFromHighRatings).Distinct().ToList();
                var combinedLocationIds = preferredLocationIds.Union(locationIdsFromHighRatings).Distinct().ToList();
                var combinedCountryIds = preferredCountryIds.Union(countryIdsFromHighRatings).Distinct().ToList();

                var preferredServiceIds = Context.ReservationServices
                    .AsNoTracking()
                    .Where(rs => rs.Reservation != null && rs.Reservation.UserId == userId)
                    .Select(rs => rs.ServiceId)
                    .Distinct()
                    .ToList();

                var candidates = activeYachts
                    .Where(y => !userReservationYachtIds.Contains(y.YachtId));

                var noPersonalSignals = combinedCategoryIds.Count == 0
                    && combinedLocationIds.Count == 0
                    && combinedCountryIds.Count == 0
                    && preferredServiceIds.Count == 0;

                signals = new RecommendationSignals
                {
                    CombinedCategoryIds = combinedCategoryIds,
                    CombinedLocationIds = combinedLocationIds,
                    CombinedCountryIds = combinedCountryIds,
                    PreferredServiceIds = preferredServiceIds,
                    PopularityFallbackOnly = noPersonalSignals,
                };

                if (noPersonalSignals)
                {
                    ordered = candidates
                        .OrderByDescending(y => y.Reservations.Count(r => r.Status != "Cancelled"))
                        .ThenByDescending(y => y.Reviews.Any(r => r.Rating.HasValue) ? y.Reviews.Average(r => r.Rating ?? 0) : 0);
                }
                else
                {
                    ordered = candidates
                        .OrderByDescending(y => combinedCategoryIds.Contains(y.CategoryId))
                        .ThenByDescending(y => combinedLocationIds.Contains(y.LocationId))
                        .ThenByDescending(y => y.Location != null && combinedCountryIds.Contains(y.Location.CountryId))
                        .ThenByDescending(y => y.YachtServices.Any(ys => preferredServiceIds.Contains(ys.ServiceId)))
                        .ThenByDescending(y => y.Reviews.Any(r => r.Rating.HasValue) ? y.Reviews.Average(r => r.Rating ?? 0) : 0)
                        .ThenByDescending(y => y.Reservations.Count(r => r.Status != "Cancelled"));
                }

                var totalCount = ordered.Count();
                var list = ordered.Skip(page * pageSize).Take(pageSize).ToList();
                return BuildRecommendationOverviewResult(list, totalCount, signals);
            }

            ordered = activeYachts
                .OrderByDescending(y => y.Reservations.Count(r => r.Status != "Cancelled"))
                .ThenByDescending(y => y.Reviews.Any(r => r.Rating.HasValue) ? y.Reviews.Average(r => r.Rating ?? 0) : 0);
            var anonymousTotal = ordered.Count();
            var anonymousList = ordered.Skip(page * pageSize).Take(pageSize).ToList();
            return BuildRecommendationOverviewResult(
                anonymousList,
                anonymousTotal,
                new RecommendationSignals { PopularityFallbackOnly = true });
        }

        private sealed class RecommendationSignals
        {
            public IReadOnlyList<int> CombinedCategoryIds { get; init; } = Array.Empty<int>();
            public IReadOnlyList<int> CombinedLocationIds { get; init; } = Array.Empty<int>();
            public IReadOnlyList<int> CombinedCountryIds { get; init; } = Array.Empty<int>();
            public IReadOnlyList<int> PreferredServiceIds { get; init; } = Array.Empty<int>();
            public bool PopularityFallbackOnly { get; init; }
        }

        /// <summary>
        /// Builds a yacht-specific explanation using the strongest personal match (city, country, category, services),
        /// then falls back to rating and booking popularity.
        /// </summary>
        private static string ResolveRecommendationReason(Database.Yacht yacht, RecommendationSignals signals)
        {
            if (signals.PopularityFallbackOnly)
                return BuildPopularityReason(yacht);

            if (signals.CombinedLocationIds.Contains(yacht.LocationId)
                && yacht.Location != null
                && !string.IsNullOrWhiteSpace(yacht.Location.Name))
            {
                return $"Similar to your past trips in {yacht.Location.Name.Trim()}.";
            }

            if (yacht.Location?.Country != null
                && signals.CombinedCountryIds.Contains(yacht.Location.CountryId)
                && !string.IsNullOrWhiteSpace(yacht.Location.Country.Name))
            {
                return $"Based in {yacht.Location.Country.Name.Trim()}, a destination you have booked before.";
            }

            if (signals.CombinedCategoryIds.Contains(yacht.CategoryId))
            {
                var categoryName = yacht.Category?.Name?.Trim();
                var cityName = yacht.Location?.Name?.Trim();
                if (!string.IsNullOrEmpty(categoryName) && !string.IsNullOrEmpty(cityName))
                {
                    return $"A {categoryName} in {cityName}, matching yachts from your booking history.";
                }

                if (!string.IsNullOrEmpty(categoryName))
                {
                    return $"Matches your interest in {categoryName} from your past bookings.";
                }
            }

            var matchedServiceNames = yacht.YachtServices
                .Where(ys => signals.PreferredServiceIds.Contains(ys.ServiceId) && ys.Service != null)
                .Select(ys => ys.Service!.Name.Trim())
                .Where(n => n.Length > 0)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(3)
                .ToList();

            if (matchedServiceNames.Count > 0)
            {
                var serviceList = FormatNameList(matchedServiceNames);
                return $"Offers {serviceList}, which you often add to your charters.";
            }

            return BuildPopularityReason(yacht);
        }

        private static string BuildPopularityReason(Database.Yacht yacht)
        {
            var rated = yacht.Reviews.Where(r => r.Rating.HasValue).ToList();
            if (rated.Count > 0)
            {
                var avg = rated.Average(r => r.Rating!.Value);
                if (avg >= 4.0)
                {
                    return $"Highly rated ({avg:F1}/5 from {rated.Count} reviews) and popular with other travelers.";
                }
            }

            var bookingCount = yacht.Reservations.Count(r =>
                !string.Equals(r.Status, "Cancelled", StringComparison.OrdinalIgnoreCase));

            if (bookingCount > 0)
            {
                return $"A popular choice with {bookingCount} booking{(bookingCount == 1 ? "" : "s")} on Yamore.";
            }

            return "Featured among our active fleet.";
        }

        private static string FormatNameList(IReadOnlyList<string> names)
        {
            if (names.Count == 0) return string.Empty;
            if (names.Count == 1) return names[0];
            if (names.Count == 2) return $"{names[0]} and {names[1]}";
            return $"{names[0]}, {names[1]}, and {names[2]}";
        }

        private PagedResponse<YachtOverviewDto> BuildRecommendationOverviewResult(
            List<Database.Yacht> list,
            int totalCount,
            RecommendationSignals? signals = null)
        {
            var yachtIds = list.Select(y => y.YachtId).ToList();
            var thumbnails = Context.YachtImages
                .Where(i => yachtIds.Contains(i.YachtId) && i.IsThumbnail)
                .Select(i => new { i.YachtId, i.YachtImageId })
                .ToDictionary(x => x.YachtId, x => x.YachtImageId);

            var result = list.Select(y => new YachtOverviewDto
            {
                YachtId = y.YachtId,
                Name = y.Name,
                LocationName = y.Location?.Name,
                CountryName = y.Location?.Country?.Name,
                OwnerName = y.Owner != null ? $"{y.Owner.FirstName} {y.Owner.LastName}".Trim() : null,
                OwnerId = y.OwnerId,
                YearBuilt = y.YearBuilt,
                Length = y.Length,
                Capacity = y.Capacity,
                PricePerDay = y.PricePerDay,
                StateMachine = y.StateMachine,
                ThumbnailImageId = thumbnails.TryGetValue(y.YachtId, out var tid) ? tid : null,
                CategoryId = y.CategoryId,
                AverageRating = y.Reviews.Any(r => r.Rating.HasValue)
                    ? y.Reviews.Where(r => r.Rating.HasValue).Average(r => (double)r.Rating!)
                    : (double?)null,
                ReviewCount = y.Reviews.Count(r => r.Rating.HasValue),
                RecommendationReason = signals == null
                    ? BuildPopularityReason(y)
                    : ResolveRecommendationReason(y, signals),
            }).ToList();

            return new PagedResponse<YachtOverviewDto> { Count = totalCount, ResultList = result };
        }

        public PagedResponse<YachtOverviewDto> GetOverviewForAdmin(YachtsSearchObject search)
        {
            search ??= new YachtsSearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);

            var query = Context.Yachts
                .Include(y => y.Owner)
                .Include(y => y.Location)
                    .ThenInclude(c => c.Country)
                .Include(y => y.Reviews)
                .AsQueryable();

            query = AddFilter(search, query);
            var count = query.Count();

            query = query.Skip(search.Page!.Value * search.PageSize!.Value).Take(search.PageSize.Value);

            var list = query.ToList();
            var yachtIds = list.Select(y => y.YachtId).ToList();
            var thumbnails = Context.YachtImages
                .Where(i => yachtIds.Contains(i.YachtId) && i.IsThumbnail)
                .Select(i => new { i.YachtId, i.YachtImageId })
                .ToDictionary(x => x.YachtId, x => x.YachtImageId);

            var result = list.Select(y => new YachtOverviewDto
            {
                YachtId = y.YachtId,
                Name = y.Name,
                LocationName = y.Location?.Name,
                CountryName = y.Location?.Country?.Name,
                OwnerName = y.Owner != null ? $"{y.Owner.FirstName} {y.Owner.LastName}".Trim() : null,
                OwnerId = y.OwnerId,
                YearBuilt = y.YearBuilt,
                Length = y.Length,
                Capacity = y.Capacity,
                PricePerDay = y.PricePerDay,
                StateMachine = y.StateMachine,
                ThumbnailImageId = thumbnails.TryGetValue(y.YachtId, out var tid) ? tid : null,
                CategoryId = y.CategoryId,
                AverageRating = y.Reviews.Any(r => r.Rating.HasValue)
                    ? y.Reviews.Where(r => r.Rating.HasValue).Average(r => (double)r.Rating!)
                    : (double?)null,
                ReviewCount = y.Reviews.Count(r => r.Rating.HasValue),
                CanActivate = CanPublishYacht(y),
            }).ToList();

            return new PagedResponse<YachtOverviewDto> { Count = count, ResultList = result };
        }

        /// <inheritdoc />
        public PagedResponse<YachtOverviewDto> GetOverviewForPublicListing(YachtsSearchObject search)
        {
            search ??= new YachtsSearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);

            var query = Context.Yachts
                .Include(y => y.Owner)
                .Include(y => y.Location)
                    .ThenInclude(c => c.Country)
                .Include(y => y.Reviews)
                .Where(y => y.StateMachine == "active")
                .AsQueryable();

            query = AddFilter(search, query);
            var count = query.Count();

            query = query.Skip(search.Page!.Value * search.PageSize!.Value).Take(search.PageSize.Value);

            var list = query.ToList();
            var yachtIds = list.Select(y => y.YachtId).ToList();
            var thumbnails = Context.YachtImages
                .Where(i => yachtIds.Contains(i.YachtId) && i.IsThumbnail)
                .Select(i => new { i.YachtId, i.YachtImageId })
                .ToDictionary(x => x.YachtId, x => x.YachtImageId);

            var result = list.Select(y => new YachtOverviewDto
            {
                YachtId = y.YachtId,
                Name = y.Name,
                LocationName = y.Location?.Name,
                CountryName = y.Location?.Country?.Name,
                OwnerName = y.Owner != null ? $"{y.Owner.FirstName} {y.Owner.LastName}".Trim() : null,
                OwnerId = y.OwnerId,
                YearBuilt = y.YearBuilt,
                Length = y.Length,
                Capacity = y.Capacity,
                PricePerDay = y.PricePerDay,
                StateMachine = y.StateMachine,
                ThumbnailImageId = thumbnails.TryGetValue(y.YachtId, out var tid) ? tid : null,
                CategoryId = y.CategoryId,
                AverageRating = y.Reviews.Any(r => r.Rating.HasValue)
                    ? y.Reviews.Where(r => r.Rating.HasValue).Average(r => (double)r.Rating!)
                    : (double?)null,
                ReviewCount = y.Reviews.Count(r => r.Rating.HasValue)
            }).ToList();

            return new PagedResponse<YachtOverviewDto> { Count = count, ResultList = result };
        }

        public PagedResponse<YachtOverviewDto> GetOverviewForOwner(int ownerId, YachtsSearchObject search)
        {
            search ??= new YachtsSearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);

            var query = Context.Yachts
                .Include(y => y.Owner)
                .Include(y => y.Location)
                    .ThenInclude(c => c.Country)
                .Include(y => y.Reviews)
                .Where(y => y.OwnerId == ownerId)
                .AsQueryable();

            query = AddFilter(search, query);
            var count = query.Count();

            query = query.Skip(search.Page!.Value * search.PageSize!.Value).Take(search.PageSize.Value);

            var list = query.ToList();
            var yachtIds = list.Select(y => y.YachtId).ToList();
            var thumbnails = Context.YachtImages
                .Where(i => yachtIds.Contains(i.YachtId) && i.IsThumbnail)
                .Select(i => new { i.YachtId, i.YachtImageId })
                .ToDictionary(x => x.YachtId, x => x.YachtImageId);

            var result = list.Select(y => new YachtOverviewDto
            {
                YachtId = y.YachtId,
                Name = y.Name,
                LocationName = y.Location?.Name,
                CountryName = y.Location?.Country?.Name,
                OwnerName = y.Owner != null ? $"{y.Owner.FirstName} {y.Owner.LastName}".Trim() : null,
                OwnerId = y.OwnerId,
                YearBuilt = y.YearBuilt,
                Length = y.Length,
                Capacity = y.Capacity,
                PricePerDay = y.PricePerDay,
                StateMachine = y.StateMachine,
                ThumbnailImageId = thumbnails.TryGetValue(y.YachtId, out var tid) ? tid : null,
                AverageRating = y.Reviews.Any(r => r.Rating.HasValue)
                    ? y.Reviews.Where(r => r.Rating.HasValue).Average(r => (double)r.Rating!)
                    : (double?)null,
                ReviewCount = y.Reviews.Count(r => r.Rating.HasValue),
                CanActivate = CanPublishYacht(y),
            }).ToList();

            return new PagedResponse<YachtOverviewDto> { Count = count, ResultList = result };
        }

        public bool CurrentUserMayManageYacht(int yachtId)
        {
            var http = _httpContextAccessor?.HttpContext;
            if (http?.User?.IsInRole(AppRoles.Admin) == true)
                return true;

            if (!int.TryParse(http?.User?.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
                return false;

            return Context.Set<Database.Yacht>().AsNoTracking().Any(y => y.YachtId == yachtId && y.OwnerId == userId);
        }

        public bool CurrentUserMayManageRoute(int routeId)
        {
            var yachtId = Context.Set<Database.Route>().AsNoTracking()
                .Where(r => r.RouteId == routeId)
                .Select(r => (int?)r.YachtId)
                .FirstOrDefault();
            if (yachtId == null)
                return false;
            return CurrentUserMayManageYacht(yachtId.Value);
        }

        public bool YachtExists(int yachtId) =>
            Context.Set<Database.Yacht>().AsNoTracking().Any(y => y.YachtId == yachtId);

        public override Model.Yacht Delete(int id)
        {
            if (!Context.Set<Database.Yacht>().AsNoTracking().Any(y => y.YachtId == id))
                throw new NotFoundException($"Yacht with id {id} not found.");
            if (!CurrentUserMayManageYacht(id))
                throw new ForbiddenException("You may only delete yachts that you own.");
            try
            {
                return base.Delete(id);
            }
            catch (DbUpdateException ex)
            {
                DeleteReferentialGuard.ThrowBusinessIfReferentialIntegrity(
                    ex,
                    "This yacht cannot be deleted because it is linked to existing reservations or other data in the system.");
                throw;
            }
        }
    }
}
