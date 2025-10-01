using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IUsersService : ICRUDService<User, UsersSearchObject, UserInsertRequest, UserUpdateRequest, UserDeleteRequest>
    {
    }
}
