using Yamore.Model;
using Yamore.Model.Requests.YachtDocument;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IYachtDocumentService : ICRUDService<YachtDocument, YachtDocumentSearchObject, YachtDocumentInsertRequest, YachtDocumentUpdateRequest, YachtDocumentDeleteRequest>
    {
    }
}
