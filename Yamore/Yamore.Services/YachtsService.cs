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

namespace Yamore.Services
{
    public class YachtsService : IYachtsService
    {
        public _220245Context Context { get; set; }
        public IMapper Mapper { get; set; }

        public YachtsService(_220245Context context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }


        public virtual List<Model.Yachts> GetList(YachtsSearchObject searchObject)   
        {
            List<Model.Yachts> result = new List<Model.Yachts>();

            var query = Context.Yachts.AsQueryable();   



            if (!string.IsNullOrWhiteSpace(searchObject?.FTS))
            {
                query = query.Where(x => x.Name.Contains(searchObject.FTS) || x.Description.Contains(searchObject.FTS));
            }


            if (searchObject?.Page.HasValue == true && searchObject?.PageSize.HasValue == true)
            {
                query = query.Skip(searchObject.Page.Value * searchObject.PageSize.Value).Take(searchObject.PageSize.Value);
            }




            var list = query.ToList();

            result = Mapper.Map(list, result);
            return result;
        }

        public Yachts Insert(YachtsInsertRequest request)
        {
            Database.Yacht entity = new Database.Yacht();          //instanciramo novu jahtu
            Mapper.Map(request, entity);                           //mapiramo podatke iz request-a u entitet

            Context.Yachts.Add(entity);                            //dodamo entitet u bazu
            Context.SaveChanges();                                 //spremimo promjene u bazu

            return Mapper.Map<Yachts>(entity);                    //vratimo mapirani entitet u model
        }
    }
}
