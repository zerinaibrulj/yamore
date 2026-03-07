using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtDocument;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class YachtDocumentController : BaseCRUDController<YachtDocument, YachtDocumentSearchObject, YachtDocumentInsertRequest, YachtDocumentUpdateRequest, YachtDocumentDeleteRequest>
    {
        public YachtDocumentController(IYachtDocumentService service)
            : base(service)
        {
        }
    }
}
