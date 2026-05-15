using System.Collections.Generic;
using Yamore.Model;
using Yamore.Model.Requests.YachtDocument;

namespace Yamore.Services.Interfaces
{
    public interface IYachtDocumentService
    {
        IReadOnlyList<YachtDocument> GetByYachtId(int yachtId);
        IReadOnlyList<YachtDocument> GetPendingForAdmin();
        YachtDocument Upload(int yachtId, int ownerUserId, YachtDocumentInsertRequest request);
        YachtDocument Verify(int documentId, int adminUserId, YachtDocumentVerifyRequest request);
        byte[]? GetFileContent(int documentId);
        bool AreMandatoryDocumentsApproved(int yachtId);
        Database.YachtDocument? GetEntity(int documentId);
    }
}
