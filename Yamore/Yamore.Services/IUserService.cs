using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services
{
    public interface IUsersService : ICRUDService<Model.User, UsersSearchObject, UserInsertRequest, UserUpdateRequest>
    {
    }
}
