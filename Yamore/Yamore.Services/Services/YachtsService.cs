using Azure.Core;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Yachts;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using Yamore.Services.YachtStateMachine;

namespace Yamore.Services.Services
{
    public class YachtsService : BaseCRUDService<Model.Yacht, YachtsSearchObject, Database.Yacht, YachtsInsertRequest, YachtsUpdateRequest, YachtsDeleteRequest>, IYachtsService
    {
        public BaseYachtState BaseYachtState { get; set; }

        public YachtsService(_220245Context context, IMapper mapper, BaseYachtState baseYachtState) 
            : base(context, mapper)
        {
            BaseYachtState = baseYachtState;
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
                var confirmedStatuses = new[] { "Confirmed", "Pending", "Completed" };
                filteredQurey = filteredQurey.Where(y =>
                    !Context.Reservations.Any(r => r.YachtId == y.YachtId && r.StartDate < to && r.EndDate > from && r.Status != "Cancelled") &&
                    !Context.YachtAvailabilities.Any(a => a.YachtId == y.YachtId && a.IsBlocked && a.StartDate < to && a.EndDate > from));
            }

            if (!string.IsNullOrWhiteSpace(search?.OrderBy))
            {
                var item = search.OrderBy.Split(' ');
                if (item.Length > 2 || item.Length == 0)
                {
                    throw new ApplicationException("You can only sort by one field!");
                }
                if (item.Length == 1)
                {
                    filteredQurey = filteredQurey.OrderBy(search.OrderBy);
                }
                else
                {
                    filteredQurey = filteredQurey.OrderBy($"{item[0]} {item[1]}");
                }
            }

            return filteredQurey;
        }



        public override Model.Yacht Insert(YachtsInsertRequest request)
        {
            var state = BaseYachtState.CreateState("initial");
            return state.Insert(request);
        }


        public override Model.Yacht Update(int id, YachtsUpdateRequest request)
        {
            var entity = GetById(id);
            var state = BaseYachtState.CreateState(entity.StateMachine);   //u entity.StateMachine se nalazi draft i on predstavlja trenutno stanje u kojem se nalazi jahta
            return state.Update(id, request);
        }

        public Model.Yacht Activate(int id)
        {
            var entity = GetById(id);
            var state = BaseYachtState.CreateState(entity.StateMachine);
            return state.Activate(id);
        }

        public Model.Yacht Hide(int id)
        {
            var entity = GetById(id);
            var state = BaseYachtState.CreateState(entity.StateMachine);
            return state.Hide(id);
        }

        public Model.Yacht Edit(int id)
        {
            var entity = GetById(id);
            var state = BaseYachtState.CreateState(entity.StateMachine);
            return state.Edit(id);
        }

        public List<string> AllowedActions(int id)
        {
            if (id <= 0)
            {
                var state = BaseYachtState.CreateState("initial");
                return state.AllowedActions(null);
            }
            else
            {
                var entity = Context.Yachts.Find(id);
                var state = BaseYachtState.CreateState(entity.StateMachine);
                return state.AllowedActions(entity);
            }
        }

        public PagedResponse<Model.Yacht> GetRecommendations(int? userId, int page = 0, int pageSize = 10)
        {
            var activeYachts = Context.Yachts.Where(y => y.StateMachine == "active").AsQueryable();
            IQueryable<Database.Yacht> query;

            if (userId.HasValue)
            {
                var userYachtIds = Context.Reservations.Where(r => r.UserId == userId && r.Status != "Cancelled")
                    .Select(r => r.YachtId).Distinct().ToList();
                var preferredCategoryIds = Context.Yachts.Where(y => userYachtIds.Contains(y.YachtId)).Select(y => y.CategoryId).Distinct().ToList();
                var preferredLocationIds = Context.Yachts.Where(y => userYachtIds.Contains(y.YachtId)).Select(y => y.LocationId).Distinct().ToList();
                query = activeYachts
                    .Where(y => !userYachtIds.Contains(y.YachtId) &&
                        (preferredCategoryIds.Contains(y.CategoryId) || preferredLocationIds.Contains(y.LocationId)))
                    .OrderByDescending(y => y.Reviews.Any() ? y.Reviews.Average(r => r.Rating ?? 0) : 0);
            }
            else
            {
                query = activeYachts
                    .OrderByDescending(y => y.Reservations.Count(r => r.Status != "Cancelled"));
            }

            var count = query.Count();
            var list = query.Skip(page * pageSize).Take(pageSize).ToList();
            var result = Mapper.Map<List<Model.Yacht>>(list);
            return new PagedResponse<Model.Yacht> { Count = count, ResultList = result };
        }

        public PagedResponse<YachtOverviewDto> GetOverviewForAdmin(YachtsSearchObject search)
        {
            var query = Context.Yachts
                .Include(y => y.Owner)
                .Include(y => y.Location)
                .AsQueryable();

            query = AddFilter(search, query);
            var count = query.Count();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
                query = query.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);

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
                OwnerName = y.Owner != null ? $"{y.Owner.FirstName} {y.Owner.LastName}".Trim() : null,
                OwnerId = y.OwnerId,
                YearBuilt = y.YearBuilt,
                Length = y.Length,
                Capacity = y.Capacity,
                PricePerDay = y.PricePerDay,
                StateMachine = y.StateMachine,
                ThumbnailImageId = thumbnails.TryGetValue(y.YachtId, out var tid) ? tid : null,
                CategoryId = y.CategoryId
            }).ToList();

            return new PagedResponse<YachtOverviewDto> { Count = count, ResultList = result };
        }

        public PagedResponse<YachtOverviewDto> GetOverviewForOwner(int ownerId, YachtsSearchObject search)
        {
            var query = Context.Yachts
                .Include(y => y.Owner)
                .Include(y => y.Location)
                .Where(y => y.OwnerId == ownerId)
                .AsQueryable();

            query = AddFilter(search, query);
            var count = query.Count();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
                query = query.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);

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
                OwnerName = y.Owner != null ? $"{y.Owner.FirstName} {y.Owner.LastName}".Trim() : null,
                OwnerId = y.OwnerId,
                YearBuilt = y.YearBuilt,
                Length = y.Length,
                Capacity = y.Capacity,
                PricePerDay = y.PricePerDay,
                StateMachine = y.StateMachine,
                ThumbnailImageId = thumbnails.TryGetValue(y.YachtId, out var tid) ? tid : null
            }).ToList();

            return new PagedResponse<YachtOverviewDto> { Count = count, ResultList = result };
        }
    }
}
