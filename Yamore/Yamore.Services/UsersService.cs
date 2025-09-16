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

        public UsersService(_220245Context context)
        {
            Context = context;
        }


        public virtual List<object> GetList()
        {
            List<object> result = new List<object>();

            var list = Context.Users.ToList();
            list.ForEach(x => result.Add(x));

            return result;
        }
    }
}
