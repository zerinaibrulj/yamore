using Yamore.Model.Requests.News;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface INewsItemService : ICRUDService<Model.NewsItem, NewsItemSearchObject, NewsItemInsertRequest, NewsItemUpdateRequest, NewsItemDeleteRequest>
    {
    }
}
