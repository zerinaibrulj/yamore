using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.SearchObjects;

namespace Yamore.Services
{
    public interface IService<TModel, TSearch>
        where TModel : class
        where TSearch : BaseSearchObject
    {
        public PagedResponse<TModel> GetPaged(TSearch search);
        public TModel GetById(int id);
    }
}
