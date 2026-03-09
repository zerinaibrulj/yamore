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
                filteredQuery = filteredQuery.Include(ur => ur.UserRoles).ThenInclude(r => r.Role);
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







        public Model.LoginResponseDto Login(string username, string password)
        {
            var entity = Context.Users.Include(x => x.UserRoles).ThenInclude(y => y.Role).FirstOrDefault(x => x.Username == username);

            if (entity == null)
                return null;

            var hash = GenerateHash(entity.PasswordSalt, password);
            if (hash != entity.PasswordHash)
                return null;

            var roles = entity.UserRoles?.Select(ur => ur.Role?.Name).Where(n => !string.IsNullOrEmpty(n)).Cast<string>().ToList() ?? new List<string>();
            return new Model.LoginResponseDto
            {
                UserId = entity.UserId,
                FirstName = entity.FirstName,
                LastName = entity.LastName,
                Email = entity.Email,
                Username = entity.Username,
                Status = entity.Status,
                Roles = roles
            };
        }

        public bool VerifyPassword(int userId, string password)
        {
            var entity = Context.Users.Find(userId);
            if (entity == null)
                return false;

            var hash = GenerateHash(entity.PasswordSalt, password);
            return hash == entity.PasswordHash;
        }

        public Model.User Register(UserInsertRequest request)
        {
            var user = Insert(request);
            var userRole = Context.Roles.FirstOrDefault(r => r.Name == "User" || r.Name == "EndUser");
            if (userRole != null)
            {
                Context.UserRoles.Add(new Database.UserRole
                {
                    UserId = user.UserId,
                    RoleId = userRole.RoleId,
                    DateModification = DateTime.UtcNow
                });
                Context.SaveChanges();
            }
            return user;
        }

        public List<Model.LoginResponseDto> GetOwners()
        {
            // For admin dropdowns we simply return ALL users,
            // together with their roles. The UI can decide how to filter.
            var list = Context.Users
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .ToList();

            var result = new List<Model.LoginResponseDto>();
            foreach (var u in list)
            {
                var roles = u.UserRoles
                    .Where(ur => ur.Role != null)
                    .Select(ur => ur.Role.Name)
                    .Where(n => !string.IsNullOrWhiteSpace(n))
                    .Distinct()
                    .ToList()!;

                result.Add(new Model.LoginResponseDto
                {
                    UserId = u.UserId,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Email = u.Email,
                    Username = u.Username,
                    Status = u.Status,
                    Roles = roles
                });
            }

            return result;
        }
    }
}
