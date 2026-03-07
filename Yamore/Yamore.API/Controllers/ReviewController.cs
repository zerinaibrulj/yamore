using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.Review;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReviewController : BaseCRUDController<Model.Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest, ReviewDeleteRequest>
    {
        private readonly IReviewService _reviewService;

        public ReviewController(IReviewService service)
            : base(service)
        {
            _reviewService = service;
        }

        [HttpPut("{id}/report")]
        public ActionResult<Model.Review> Report(int id)
        {
            var result = _reviewService.Report(id);
            return Ok(result);
        }

        [HttpPut("{id}/respond")]
        [Authorize(Roles = "Admin,YachtOwner")]
        public ActionResult<Model.Review> RespondAsOwner(int id, [FromBody] ReviewRespondRequest request)
        {
            var result = _reviewService.RespondAsOwner(id, request?.OwnerResponse ?? "");
            return Ok(result);
        }
    }
}
