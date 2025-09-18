using Yamore.Model;

namespace Yamore.Services
{
    public interface IUsersService
    {
        List<Model.User> GetList();
        User Insert(User request);
    }
}
