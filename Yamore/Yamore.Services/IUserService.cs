using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services
{
    public interface IUsersService
    {
        PagedResult<Model.User> GetList(UsersSearchObject searchObject);
        User Insert(UserInsertRequest request);
        User Update(int id, UserUpdateRequest request);
    }
}
