using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.Requests.Yachts;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IYachtsService : ICRUDService<Yacht, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest, YachtsDeleteRequest>
    {
        public Yacht Activate(int id);    //dodali smo ove metode u interfejs da bi mogli da ih koristimo u controlleru
        public Yacht Hide(int id);
        public Yacht Edit(int id);
        public List<string> AllowedActions(int id);
    }
}
