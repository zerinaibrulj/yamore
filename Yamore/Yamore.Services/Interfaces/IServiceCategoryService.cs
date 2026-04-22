using Yamore.Model;
using Yamore.Model.Requests.ServiceCategory;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface IServiceCategoryService : ICRUDService<ServiceCategory, ServiceCategorySearchObject, ServiceCategoryInsertRequest, ServiceCategoryUpdateRequest, ServiceCategoryDeleteRequest>
    {
        string? GetDeleteBlockingErrorMessage(int serviceCategoryId);
    }
}
