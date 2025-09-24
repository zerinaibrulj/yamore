using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services
{
    public interface IYachtCategoryService
    {
        List<Model.YachtCategory> GetList(YachtCategorySearchObject searchObject);
        YachtCategory Insert(YachtCategoryInsertRequest request);
    }
}
