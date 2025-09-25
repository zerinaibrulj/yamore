using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;

namespace Yamore.Services
{
    public class YachtCategoryService : IYachtCategoryService
    {
        public _220245Context Context { get; set; }
        public IMapper Mapper { get; set; }

        public YachtCategoryService(_220245Context context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }



        public virtual List<Model.YachtCategory> GetList(YachtCategorySearchObject searchObject)
        {
            List<Model.YachtCategory> result = new List<Model.YachtCategory>();

            var query = Context.YachtCategories.AsQueryable();  
            



            if (!string.IsNullOrWhiteSpace(searchObject?.NameGTE))
            {
                query = query.Where(x => x.Name.StartsWith(searchObject.NameGTE));
            }


            if (searchObject?.Page.HasValue == true && searchObject?.PageSize.HasValue == true)
            {
                query = query.Skip(searchObject.Page.Value * searchObject.PageSize.Value).Take(searchObject.PageSize.Value);
            }



            var list = query.ToList();
            result = Mapper.Map(list, result);

            return result;
        }

        public Model.YachtCategory Insert(YachtCategoryInsertRequest request)
        {
            Database.YachtCategory entity = new Database.YachtCategory();         
            Mapper.Map(request, entity);


            Context.YachtCategories.Add(entity);
            Context.SaveChanges();


            return Mapper.Map<Model.YachtCategory>(entity);
        }

        public Model.YachtCategory Update(int id, YachtCategoryUpdateRequest request)
        {
            var entity = Context.YachtCategories.Find(id);

            Mapper.Map(request, entity);

          
            Context.SaveChanges();
            return Mapper.Map<Model.YachtCategory>(entity);
        }
    }
}
