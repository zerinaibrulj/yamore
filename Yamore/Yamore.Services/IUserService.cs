using Yamore.Model;
using Yamore.Model.Requests;

namespace Yamore.Services
{
    public interface IUsersService
    {
        List<Model.User> GetList();
        User Insert(UserInsertRequest request);
    }
}
