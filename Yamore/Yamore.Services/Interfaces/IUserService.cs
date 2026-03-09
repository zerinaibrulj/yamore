using Yamore.Model;
using Yamore.Model.Requests.User;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IUsersService : ICRUDService<User, UsersSearchObject, UserInsertRequest, UserUpdateRequest, UserDeleteRequest>
    {
        Model.LoginResponseDto? Login(string username, string password);
        bool VerifyPassword(int userId, string password);
        /// <summary>Register a new end user and assign default "User" role.</summary>
        Model.User Register(UserInsertRequest request);
        /// <summary>All users that have owner/yacht-owner role (for dropdowns).</summary>
        List<Model.LoginResponseDto> GetOwners();
    }
}
