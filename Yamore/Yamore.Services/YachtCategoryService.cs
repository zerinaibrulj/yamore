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
    public class YachtCategoryService : BaseCRUDService<Model.YachtCategory, YachtCategorySearchObject, Database.YachtCategory, YachtCategoryInsertRequest, YachtCategoryUpdateRequest>, IYachtCategoryService
    {
        public YachtCategoryService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
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
