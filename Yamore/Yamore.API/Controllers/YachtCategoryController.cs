using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore.Storage;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtCategoryController : BaseCRUDController<Model.YachtCategory, YachtCategorySearchObject, YachtCategoryInsertRequest, YachtCategoryUpdateRequest, YachtCategoryDeleteRequest>
        
    {
        public YachtCategoryController(IYachtCategoryService service)
            : base(service)
        {
        }
    }
}
