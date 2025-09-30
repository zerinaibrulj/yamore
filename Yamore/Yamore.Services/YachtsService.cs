using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;

namespace Yamore.Services
{
    public class YachtsService : BaseCRUDService<Model.Yachts, YachtsSearchObject, Database.Yacht, YachtsInsertRequest, YachtsUpdateRequest>, IYachtsService
    {
        public YachtsService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }
    }
}
