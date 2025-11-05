using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using Yamore.Model;
using Yamore.Model.Requests.User;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using System.Linq.Dynamic.Core;

namespace Yamore.Services.Services
{
    public class UsersService : BaseCRUDService<Model.User, UsersSearchObject, Database.User, UserInsertRequest, UserUpdateRequest, UserDeleteRequest>, IUsersService    //Database.User -> predstavlja tabelu s kojom radimo
    {
        public UsersService(_220245Context context, IMapper mapper)
            : base(context, mapper)                                                                 //proslijedit cemo ono sto je potrebno baznoj klasi a to su context i mapper
        {

        }       

        public override IQueryable<Database.User> AddFilter(UsersSearchObject search, IQueryable<Database.User> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FirstNameGTE))
            {
                filteredQuery = filteredQuery.Where(x => x.FirstName.StartsWith(search.FirstNameGTE));
            }

            if (!string.IsNullOrWhiteSpace(search?.LastNameGTE))
            {
                filteredQuery = filteredQuery.Where(x => x.LastName.StartsWith(search.LastNameGTE));
            }

            if (!string.IsNullOrWhiteSpace(search?.Email))
            {
                filteredQuery = filteredQuery.Where(x => x.Email == search.Email);
            }

            if (!string.IsNullOrWhiteSpace(search?.Username))
            {
                filteredQuery = filteredQuery.Where(x => x.Username == search.Username);
            }

            if (search?.IsUserRoleIncluded == true)
            {
                filteredQuery = filteredQuery.Include(x => x.UserRoles).ThenInclude(x => x.RoleId);
            }

            if (!string.IsNullOrWhiteSpace(search?.OrderBy))
            {
                var item = search.OrderBy.Split(' ');
                if(item.Length>2 || item.Length == 0)
                {
                    throw new ApplicationException("You can only sort by one field!");
                }
                if (item.Length == 1)
                {
                    filteredQuery = filteredQuery.OrderBy(search.OrderBy);
                }
                else
                {
                    filteredQuery = filteredQuery.OrderBy($"{item[0]} {item[1]}");
                }
            }


            return filteredQuery;
        }



        public override void BeforeInsret(UserInsertRequest request, Database.User entity)  //dodajemo samo ono sto je karakteristicno za Insert korisnika
        {
            if (request.Password != request.PasswordConfirmation)
            {
                throw new Exception("Password and password confirmation must match!");
            }
      
            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);

            base.BeforeInsret(request, entity);
        }


        public override void BeforeUpdate(UserUpdateRequest request, Database.User entity)
        {
            base.BeforeUpdate(request, entity);

            if (request.Password != null)
            {
                if (request.Password != request.PasswordConfirmation)
                {
                    throw new Exception("Password and password confirmation must match!");
                }
                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            }  
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

            Buffer.BlockCopy(src, 0, dst, 0, src.Length);
            Buffer.BlockCopy(bytes, 0, dst, src.Length, bytes.Length);

            HashAlgorithm algorithm = HashAlgorithm.Create("SHA1");
            byte[] inArray = algorithm.ComputeHash(dst);
            return Convert.ToBase64String(inArray);
        }







        public Model.User Login(string username, string password)
        {
            var entity = Context.Users.Include(x => x.UserRoles).ThenInclude(y => y.Role).FirstOrDefault(x => x.Username == username);

            if (entity == null)     //ako ne postoji u bazi korisnik sa tim username-om
            {
                return null;    
            }

            var hash = GenerateHash(entity.PasswordSalt, password);

            if (hash != entity.PasswordHash)          //ako je korsnik pogrijesio password opet vrati null
            {
                return null;
            }

            return Mapper.Map<Model.User>(entity);
        }
    }
}
