using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Services.Database;

namespace Yamore.Services
{
    public class UsersService : IUsersService
    {
        public _220245Context Context { get; set; }
        public IMapper Mapper { get; set; }

        public UsersService(_220245Context context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }


        public virtual List<Model.User> GetList()
        {
            List<Model.User> result = new List<Model.User>();
            var list = Context.Users.ToList();    // Linq query to get all users from the database
           

            result = Mapper.Map<List<Model.User>>(list);      // ili result=Mapper.Map(list, result);
            return result;
        }

        public Model.User Insert(Model.User request)
        {
            throw new NotImplementedException();
        }
    }
}
