using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.News;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    /// <summary>Platform news (obavijesti): read for all signed-in users; create/update/delete for Admins.</summary>
    [Route("news")]
    [ApiController]
    public class NewsItemController
        : BaseCRUDController<Model.NewsItem, NewsItemSearchObject, NewsItemInsertRequest, NewsItemUpdateRequest, NewsItemDeleteRequest>
    {
        public NewsItemController(INewsItemService service)
            : base(service)
        {
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.NewsItem> Insert(NewsItemInsertRequest request) => base.Insert(request);

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.NewsItem> Update(int id, NewsItemUpdateRequest request) => base.Update(id, request);

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override ActionResult<Model.NewsItem> Delete(int id) => base.Delete(id);
    }
}
