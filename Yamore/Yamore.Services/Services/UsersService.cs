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

        /// <summary>
        /// Custom implementation of GetPaged to avoid Mapster mapping cycles for User ↔ UserRole.
        /// We manually project the EF entities into lightweight model objects.
        /// </summary>
        public override PagedResponse<Model.User> GetPaged(UsersSearchObject search)
        {
            var query = Context.Users.AsQueryable();

            // Apply common filters (including optional role includes/filters)
            query = AddFilter(search, query);

            var count = query.Count();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                query = query
                    .Skip(search.Page.Value * search.PageSize.Value)
                    .Take(search.PageSize.Value);
            }

            // Materialize and manually map to break any navigation cycles.
            var list = query
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .ToList();

            var result = new List<Model.User>();

            foreach (var u in list)
            {
                var modelUser = new Model.User
                {
                    UserId = u.UserId,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Email = u.Email,
                    Phone = u.Phone,
                    Username = u.Username,
                    Status = u.Status,
                };

                // Only populate roles when requested to keep payloads small.
                if (search?.IsUserRoleIncluded == true || !string.IsNullOrWhiteSpace(search?.RoleName))
                {
                    var userRoles = new List<Model.UserRole>();
                    foreach (var ur in u.UserRoles)
                    {
                        var role = ur.Role != null
                            ? new Model.Role
                            {
                                RoleId = ur.Role.RoleId,
                                Name = ur.Role.Name,
                                Description = ur.Role.Description,
                                UserRoles = new List<Model.UserRole>() // avoid cycles
                            }
                            : null;

                        userRoles.Add(new Model.UserRole
                        {
                            UserRoleId = ur.UserRoleId,
                            UserId = ur.UserId,
                            RoleId = ur.RoleId,
                            DateModification = ur.DateModification,
                            Role = role!
                        });
                    }

                    modelUser.UserRoles = userRoles;
                }

                result.Add(modelUser);
            }

            return new PagedResponse<Model.User>
            {
                ResultList = result,
                Count = count
            };
        }

        public override Model.User GetById(int id)
        {
            var entity = Context.Users
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .FirstOrDefault(u => u.UserId == id);

            if (entity == null)
                return null;

            return MapUserSafe(entity);
        }

        public override Model.User Update(int id, UserUpdateRequest request)
        {
            var entity = Context.Users.Find(id);
            if (entity == null)
                throw new KeyNotFoundException($"User with id {id} not found.");

            Mapper.Map(request, entity);
            BeforeUpdate(request, entity);

            Context.SaveChanges();

            Context.Entry(entity).Collection(u => u.UserRoles).Load();
            foreach (var ur in entity.UserRoles)
                Context.Entry(ur).Reference(r => r.Role).Load();

            return MapUserSafe(entity);
        }

        private static Model.User MapUserSafe(Database.User u)
        {
            var modelUser = new Model.User
            {
                UserId = u.UserId,
                FirstName = u.FirstName,
                LastName = u.LastName,
                Email = u.Email,
                Phone = u.Phone,
                Username = u.Username,
                Status = u.Status,
            };

            var userRoles = new List<Model.UserRole>();
            foreach (var ur in u.UserRoles)
            {
                var role = ur.Role != null
                    ? new Model.Role
                    {
                        RoleId = ur.Role.RoleId,
                        Name = ur.Role.Name,
                        Description = ur.Role.Description,
                        UserRoles = new List<Model.UserRole>()
                    }
                    : null;

                userRoles.Add(new Model.UserRole
                {
                    UserRoleId = ur.UserRoleId,
                    UserId = ur.UserId,
                    RoleId = ur.RoleId,
                    DateModification = ur.DateModification,
                    Role = role!
                });
            }

            modelUser.UserRoles = userRoles;
            return modelUser;
        }

        public override IQueryable<Database.User> AddFilter(UsersSearchObject search, IQueryable<Database.User> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            // Name search: when both FirstNameGTE and LastNameGTE are provided (as in the admin UI),
            // treat them as a single search term that matches either first OR last name.
            if (!string.IsNullOrWhiteSpace(search?.FirstNameGTE) &&
                !string.IsNullOrWhiteSpace(search.LastNameGTE) &&
                string.Equals(search.FirstNameGTE!.Trim(), search.LastNameGTE!.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                var term = search.FirstNameGTE.Trim();
                filteredQuery = filteredQuery.Where(x =>
                    x.FirstName.StartsWith(term) || x.LastName.StartsWith(term));
            }
            else
            {
                if (!string.IsNullOrWhiteSpace(search?.FirstNameGTE))
                {
                    var first = search.FirstNameGTE.Trim();
                    filteredQuery = filteredQuery.Where(x => x.FirstName.StartsWith(first));
                }

                if (!string.IsNullOrWhiteSpace(search?.LastNameGTE))
                {
                    var last = search.LastNameGTE.Trim();
                    filteredQuery = filteredQuery.Where(x => x.LastName.StartsWith(last));
                }
            }

            if (!string.IsNullOrWhiteSpace(search?.Email))
            {
                var email = search.Email.Trim();
                filteredQuery = filteredQuery.Where(x => x.Email == email);
            }

            if (!string.IsNullOrWhiteSpace(search?.Username))
            {
                var username = search.Username.Trim();
                filteredQuery = filteredQuery.Where(x => x.Username == username);
            }

            if (search?.Status != null)
            {
                filteredQuery = filteredQuery.Where(x => x.Status == search.Status);
            }

            if (search?.IsUserRoleIncluded == true || !string.IsNullOrWhiteSpace(search?.RoleName))
            {
                filteredQuery = filteredQuery.Include(u => u.UserRoles).ThenInclude(ur => ur.Role);
            }

            if (!string.IsNullOrWhiteSpace(search?.RoleName))
            {
                var roleName = search.RoleName.Trim();
                filteredQuery = filteredQuery.Where(u =>
                    u.UserRoles.Any(ur => ur.Role != null && ur.Role.Name == roleName));
            }

            if (!string.IsNullOrWhiteSpace(search?.OrderBy))
            {
                var item = search.OrderBy.Split(' ');
                if (item.Length > 2 || item.Length == 0)
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

        public override Model.User Insert(UserInsertRequest request)
        {
            var user = base.Insert(request);

            if (!string.IsNullOrWhiteSpace(request.RoleName))
            {
                var roleName = request.RoleName!.Trim();
                var role = Context.Roles.FirstOrDefault(r => r.Name == roleName);
                if (role != null)
                {
                    Context.UserRoles.Add(new Database.UserRole
                    {
                        UserId = user.UserId,
                        RoleId = role.RoleId,
                        DateModification = DateTime.UtcNow
                    });
                    Context.SaveChanges();
                }
            }

            return user;
        }


        public override void BeforeUpdate(UserUpdateRequest request, Database.User entity)
        {
            // Enforce unique email if it is being changed.
            if (!string.IsNullOrWhiteSpace(request.Email) &&
                !string.Equals(request.Email!.Trim(), entity.Email, StringComparison.OrdinalIgnoreCase))
            {
                var email = request.Email.Trim();
                var emailInUse = Context.Users
                    .Any(u => u.UserId != entity.UserId && u.Email != null && u.Email == email);

                if (emailInUse)
                {
                    throw new UserException("The specified email address is already in use by another user.");
                }
            }

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
            // For public registration, fall back to default User / EndUser role.
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
