using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.Requests.Yachts;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtsController : BaseCRUDController<Model.Yacht, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest, YachtsDeleteRequest>
    {
        private readonly IYachtsService _yachtsService;

        public YachtsController(IYachtsService service)
            : base(service)
        {
            _yachtsService = service;
        }

        [HttpPut("{id}/activate")]
        [Authorize(Roles = "Admin,YachtOwner")]
        public Yacht Activate(int id)
        {
            return _yachtsService.Activate(id);
        }

        [HttpPut("{id}/hide")]
        [Authorize(Roles = "Admin,YachtOwner")]
        public Yacht Hide(int id)
        {
            return _yachtsService.Hide(id);
        }

        [HttpPut("{id}/edit")]
        public Yacht Edit(int id)
        {
            return _yachtsService.Edit(id);
        }

        [HttpGet("{id}/allowedActions")]
        public List<string> AllowedActions(int id)
        {
            return _yachtsService.AllowedActions(id);
        }

        [HttpGet("recommendations")]
        public PagedResponse<Yacht> GetRecommendations([FromQuery] int? userId, [FromQuery] int page = 0, [FromQuery] int pageSize = 10)
        {
            var currentUserId = User?.FindFirstValue(ClaimTypes.NameIdentifier);
            var id = userId ?? (int.TryParse(currentUserId, out var uid) ? (int?)uid : null);
            return _yachtsService.GetRecommendations(id, page, pageSize);
        }

        [HttpGet("admin/overview")]
        [Authorize(Roles = "Admin")]
        public PagedResponse<YachtOverviewDto> GetOverviewForAdmin([FromQuery] YachtsSearchObject search)
        {
            return _yachtsService.GetOverviewForAdmin(search ?? new YachtsSearchObject());
        }
    }
}
