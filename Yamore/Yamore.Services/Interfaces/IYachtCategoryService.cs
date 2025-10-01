using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IYachtCategoryService : ICRUDService<YachtCategory, YachtCategorySearchObject, YachtCategoryInsertRequest, YachtCategoryUpdateRequest, YachtCategoryDeleteRequest>
    {
     
    }
}
