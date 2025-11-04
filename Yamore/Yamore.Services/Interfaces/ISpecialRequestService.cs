using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.SpecialRequest;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface ISpecialRequestService : ICRUDService<Model.SpecialRequest, SpecialRequestSearchObject, SpecialRequestInsertRequest, SpecialRequestUpdateRequest, SpecialRequestDeleteRequest>
    {
    }
}
