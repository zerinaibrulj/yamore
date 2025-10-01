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
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class YachtsService : BaseCRUDService<Model.Yacht, YachtsSearchObject, Database.Yacht, YachtsInsertRequest, YachtsUpdateRequest, YachtsDeleteRequest>, IYachtsService
    {
        public YachtsService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }
    }
}
