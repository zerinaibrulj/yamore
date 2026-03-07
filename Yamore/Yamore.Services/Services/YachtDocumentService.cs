using System.Linq;
using MapsterMapper;
using Yamore.Model.Requests.YachtDocument;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class YachtDocumentService : BaseCRUDService<Model.YachtDocument, YachtDocumentSearchObject, Database.YachtDocument, YachtDocumentInsertRequest, YachtDocumentUpdateRequest, YachtDocumentDeleteRequest>, IYachtDocumentService
    {
        public YachtDocumentService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.YachtDocument> AddFilter(YachtDocumentSearchObject search, IQueryable<Database.YachtDocument> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (search?.YachtId != null)
                filteredQuery = filteredQuery.Where(x => x.YachtId == search.YachtId);

            if (!string.IsNullOrWhiteSpace(search?.DocumentType))
                filteredQuery = filteredQuery.Where(x => x.DocumentType == search.DocumentType);

            return filteredQuery;
        }
    }
}
