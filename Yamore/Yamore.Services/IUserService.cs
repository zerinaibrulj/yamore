using Yamore.Model;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services
{
    public interface IUsersService : ICRUDService<User, UsersSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        //PagedResult<Model.User> GetList(UsersSearchObject searchObject);
        //User Insert(UserInsertRequest request);        //moramo ove dvije dodati u IService
        //User Update(int id, UserUpdateRequest request);
    }
}
