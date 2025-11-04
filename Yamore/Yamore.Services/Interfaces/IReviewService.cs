using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Review;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IReviewService : ICRUDService<Model.Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest, ReviewDeleteRequest>
    {
    }
}
