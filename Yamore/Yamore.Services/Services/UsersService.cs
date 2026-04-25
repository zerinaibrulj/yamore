using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.User;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using System.Linq.Dynamic.Core;

namespace Yamore.Services.Services
{
    public class UsersService : BaseCRUDService<Model.User, UsersSearchObject, Database.User, UserInsertRequest, UserUpdateRequest, UserDeleteRequest>, IUsersService
    {
        public UsersService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        /// <summary>
        /// Custom implementation of GetPaged to avoid Mapster mapping cycles for User ↔ UserRole.
        /// We manually project the EF entities into lightweight model objects.
        /// </summary>
        public override PagedResponse<Model.User> GetPaged(UsersSearchObject search)
        {
            search ??= new UsersSearchObject();
            search.Page = PagingConstraints.NormalizePage(search.Page);
            search.PageSize = PagingConstraints.NormalizePageSize(search.PageSize);

            var query = Context.Users.AsQueryable();

            query = AddFilter(search, query);

            var count = query.Count();

            query = query
                .Skip(search.Page!.Value * search.PageSize!.Value)
                .Take(search.PageSize.Value);

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
                throw new NotFoundException($"User with id {id} not found.");

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
                    throw new UserException("You can only sort by one field!");
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



        public override void BeforeInsret(UserInsertRequest request, Database.User entity)
        {
            if (request.Password != request.PasswordConfirmation)
            {
                throw new UserException("Password and password confirmation must match!");
            }

            // BCrypt embeds salt; do not use SHA-1+salt.
            entity.PasswordSalt = string.Empty;
            entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password, workFactor: 11);

            base.BeforeInsret(request, entity);
        }

        public override Model.User Insert(UserInsertRequest request)
        {
            using var transaction = Context.Database.BeginTransaction();
            try
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

                transaction.Commit();
                return user;
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }


        public override void BeforeUpdate(UserUpdateRequest request, Database.User entity)
        {
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
                    throw new UserException("Password and password confirmation must match!");
                }
                entity.PasswordSalt = string.Empty;
                entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password, workFactor: 11);
            }
        }



        public static string GenerateSalt()
        {
            var byteArray = new byte[16];
            RandomNumberGenerator.Fill(byteArray);
            return Convert.ToBase64String(byteArray);
        }


        public static string GenerateHash(string salt, string password)
        {
            byte[] src = Convert.FromBase64String(salt);
            byte[] bytes = Encoding.Unicode.GetBytes(password);
            byte[] dst = new byte[src.Length + bytes.Length];

            Buffer.BlockCopy(src, 0, dst, 0, src.Length);
            Buffer.BlockCopy(bytes, 0, dst, src.Length, bytes.Length);

            using var algorithm = SHA1.Create();
            byte[] inArray = algorithm.ComputeHash(dst);
            return Convert.ToBase64String(inArray);
        }







        public static bool IsBcryptPasswordHash(string? passwordHash) =>
            !string.IsNullOrEmpty(passwordHash) &&
            (passwordHash.StartsWith("$2a$", StringComparison.Ordinal) ||
             passwordHash.StartsWith("$2b$", StringComparison.Ordinal) ||
             passwordHash.StartsWith("$2y$", StringComparison.Ordinal));

        public Model.LoginResponseDto Login(string username, string password)
        {
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrEmpty(password))
                return null;

            var u = username.Trim();
            var entity = Context.Users
                .Include(x => x.UserRoles)
                .ThenInclude(y => y.Role)
                .FirstOrDefault(x => x.Username != null
                    && x.Username.ToLower() == u.ToLower());

            if (entity == null)
                return null;

            if (IsBcryptPasswordHash(entity.PasswordHash))
            {
                if (!BCrypt.Net.BCrypt.Verify(password, entity.PasswordHash))
                    return null;
            }
            else
            {
                if (string.IsNullOrEmpty(entity.PasswordSalt)
                    || GenerateHash(entity.PasswordSalt, password) != entity.PasswordHash)
                {
                    return null;
                }

                entity.PasswordHash = BCrypt.Net.BCrypt.HashPassword(password, workFactor: 11);
                entity.PasswordSalt = string.Empty;
                Context.SaveChanges();
            }

            var roles = entity.UserRoles?.Select(ur => ur.Role?.Name).Where(n => !string.IsNullOrEmpty(n)).Cast<string>().ToList() ?? new List<string>();
            return new Model.LoginResponseDto
            {
                UserId = entity.UserId,
                FirstName = entity.FirstName,
                LastName = entity.LastName,
                Email = entity.Email,
                Phone = entity.Phone,
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
            if (IsBcryptPasswordHash(entity.PasswordHash))
                return BCrypt.Net.BCrypt.Verify(password, entity.PasswordHash);
            return !string.IsNullOrEmpty(entity.PasswordSalt) &&
                   GenerateHash(entity.PasswordSalt, password) == entity.PasswordHash;
        }

        public Model.User Register(UserInsertRequest request)
        {
            var safe = new UserInsertRequest
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Phone = request.Phone,
                Username = request.Username,
                Password = request.Password,
                PasswordConfirmation = request.PasswordConfirmation,
                // Self-registration: server assigns default role; ignore client role/status/flags.
                Status = true,
                RoleName = null,
            };
            var user = Insert(safe);
            var userRole = Context.Roles.FirstOrDefault(r => r.Name == AppRoles.User || r.Name == AppRoles.EndUser);
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

        public PagedResponse<Model.LoginResponseDto> GetOwnersPaged(int page, int pageSize)
        {
            page = PagingConstraints.NormalizePage(page);
            pageSize = PagingConstraints.NormalizePageSize(pageSize);

            var query = Context.Users
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .Where(u => u.UserRoles.Any(ur => ur.Role != null &&
                    (ur.Role.Name == AppRoles.YachtOwner || ur.Role.Name == AppRoles.Owner)))
                .OrderBy(u => u.FirstName)
                .ThenBy(u => u.LastName);

            var count = query.Count();
            var list = query.Skip(page * pageSize).Take(pageSize).ToList();

            var result = new List<Model.LoginResponseDto>();
            foreach (var u in list)
            {
                var roles = u.UserRoles
                    .Where(ur => ur.Role != null)
                    .Select(ur => ur.Role!.Name)
                    .Where(n => !string.IsNullOrWhiteSpace(n))
                    .Distinct()
                    .ToList();

                result.Add(new Model.LoginResponseDto
                {
                    UserId = u.UserId,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Email = u.Email,
                    Phone = u.Phone,
                    Username = u.Username,
                    Status = u.Status,
                    Roles = roles
                });
            }

            return new PagedResponse<Model.LoginResponseDto>
            {
                Count = count,
                ResultList = result,
            };
        }
    }
}
