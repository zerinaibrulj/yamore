using Azure.Core;
using MapsterMapper;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.EntityFrameworkCore.SqlServer.Query.Internal;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;

namespace Yamore.Services
{
    public abstract class BaseCRUDService<TModel, TSearch, TDbEntity, TInsert, TUpdate> : BaseService<TModel, TSearch, TDbEntity>, ICRUDService<TModel, TSearch, TInsert, TUpdate>
        where TModel : class
        where TSearch : BaseSearchObject
        where TDbEntity : class
    {
        public BaseCRUDService(_220245Context context, IMapper mapper) 
            : base(context, mapper)
        {
        }

        public virtual TModel Insert(TInsert request)
        {
            TDbEntity entity = Mapper.Map<TDbEntity>(request);

            BeforeInsret(request, entity);


            Context.Add(entity);
            Context.SaveChanges();

            return Mapper.Map<TModel>(entity);
        }


        public virtual void BeforeInsret(TInsert request, TDbEntity entity)
        {
        }



        public virtual TModel Update(int id, TUpdate request)
        {
            var set = Context.Set<TDbEntity>();
            var entity = set.Find(id);

            Mapper.Map(request, entity);
            BeforeUpdate(request, entity);                           //prije snimanja u bazu pozvat cemo metodu BeforeUpdate


            Context.SaveChanges();
            return Mapper.Map<TModel>(entity);
        }



        public virtual void BeforeUpdate(TUpdate request, TDbEntity entity)
        {
     
        }
    }
}
