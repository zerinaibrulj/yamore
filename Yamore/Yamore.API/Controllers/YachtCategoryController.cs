using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore.Storage;
using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    //[AllowAnonymous]                // cijeli endpoint ce biti dostupan anonimnim korisnicima
    public class YachtCategoryController : BaseCRUDController<Model.YachtCategory, YachtCategorySearchObject, YachtCategoryInsertRequest, YachtCategoryUpdateRequest, YachtCategoryDeleteRequest>
        
    {
        public YachtCategoryController(IYachtCategoryService service)
            : base(service)
        {
        }

        [Authorize(Roles = "Admin")]                      // samo admin moze da dodaje nove kategorije
        //public override YachtCategory Insert(YachtCategoryInsertRequest request)
        //{
        //    return base.Insert(request);
        //}

        [AllowAnonymous]                                // samo ova metoda je dostupna anonimnim korisnicima (korisnik ne mora biti logovan da bi pristupio ovoj metodi)
        public override PagedResponse<YachtCategory> GetPaged([FromQuery] YachtCategorySearchObject search)
        {
            return base.GetPaged(search);
        }
    }
}
