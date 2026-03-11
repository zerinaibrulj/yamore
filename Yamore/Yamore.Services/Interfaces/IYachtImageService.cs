using System.Collections.Generic;
using Yamore.Model;
using Yamore.Model.Requests.YachtImage;

namespace Yamore.Services.Interfaces
{
    public interface IYachtImageService
    {
        List<Model.YachtImage> GetByYachtId(int yachtId);
        Database.YachtImage? GetRawById(int imageId);
        Model.YachtImage Upload(int yachtId, YachtImageInsertRequest request);
        void Delete(int imageId);
        void SetThumbnail(int imageId);
    }
}
