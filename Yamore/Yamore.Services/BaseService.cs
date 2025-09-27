using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;

namespace Yamore.Services
{
    public abstract class BaseService<TModel, TSearch, TDbEntity> : IService<TModel, TSearch>
        where TSearch : BaseSearchObject 
        where TDbEntity : class
        where TModel : class
    {
        public _220245Context Context { get; set; }
        public IMapper Mapper { get; set; }

        public BaseService(_220245Context context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }



        public PagedResponse<TModel> GetPaged(TSearch search)
        {
            List<TModel> result = new List<TModel>();
            var query = Context.Set<TDbEntity>().AsQueryable();


            query = AddFilter(search, query);
            int count = query.Count();

        
            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);
            }


            var list = query.ToList();
            result = Mapper.Map(list, result);

            PagedResponse<TModel> response = new PagedResponse<TModel>();

            response.ResultList = result;   
            response.Count = count;         


            return response;
        }



        public virtual IQueryable<TDbEntity> AddFilter(TSearch search, IQueryable<TDbEntity> query)
        {
            return query;
        }




        public TModel GetById(int id)
        {
            var entity = Context.Set<TDbEntity>().Find(id);

            if(entity !=null)
                return Mapper.Map<TModel>(entity);
            else
                return null;
        }
    }
}
