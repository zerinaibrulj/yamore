using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests;
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

        public Model.User Insert(UserInsertRequest request)
        {
            if (request.Password != request.PasswordConfirmation)
            {
                throw new Exception("Password and password confirmation must match!");
            }

            Database.User entity = new Database.User();         //instanciramo novog korisnika
            Mapper.Map(request, entity);


            //entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordHash, request.Password);

            Context.Users.Add(entity);
            Context.SaveChanges();

            return Mapper.Map<Model.User>(entity);
        }


        public static string GenerateSalt()
        {
            RNGCryptoServiceProvider provider = new RNGCryptoServiceProvider();
            var byteArray = new byte[16];
            provider.GetBytes(byteArray);

            return Convert.ToBase64String(byteArray);
        }

        public static string GenerateHash(string salt, string password)
        {
            byte[] src = Convert.FromBase64String(salt);
            byte[] bytes = Encoding.Unicode.GetBytes(password);
            byte[] dst = new byte[src.Length + bytes.Length];

            System.Buffer.BlockCopy(src, 0, dst, 0, src.Length);
            System.Buffer.BlockCopy(bytes, 0, dst, src.Length, bytes.Length);

            HashAlgorithm algorithm = HashAlgorithm.Create("SHA1");
            byte[] inArray = algorithm.ComputeHash(dst);
            return Convert.ToBase64String(inArray);
        }
    }
}
