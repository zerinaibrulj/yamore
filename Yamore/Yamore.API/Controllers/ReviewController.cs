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
        public ReviewController(IReviewService service) 
            : base(service)
        {
        }
    }
}
