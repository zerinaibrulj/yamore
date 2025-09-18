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


        public virtual List<Model.User> GetList()
        {
            List<Model.User> result = new List<Model.User>();

            var list = Context.Users.ToList();    // Linq query to get all users from the database
            list.ForEach(x => result.Add(new Model.User
            {
                UserId=x.UserId,
                FirstName=x.FirstName,
                LastName=x.LastName,
                Email=x.Email,
                Phone=x.Phone,   
            }));

            return result;
        }
    }
}
