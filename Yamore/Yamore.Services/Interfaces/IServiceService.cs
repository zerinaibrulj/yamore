using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Service;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IServiceService : ICRUDService<Model.Service, ServiceSearchObject, ServiceInsertRequest, ServiceUpdateRequest, ServiceDeleteRequest>
    {
    }
}
