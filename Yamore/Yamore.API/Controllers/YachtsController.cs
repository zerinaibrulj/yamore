using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.Requests.Yachts;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class YachtsController : BaseCRUDController<Model.Yacht, YachtsSearchObject, YachtsInsertRequest, YachtsUpdateRequest, YachtsDeleteRequest>
    {
        public YachtsController(IYachtsService service) 
            : base(service)
        {
        }


        [HttpPut("{id}/activate")]
        public Yacht Activate(int id)
        {
            return (_service as IYachtsService).Activate(id);
        }

        [HttpPut("{id}/hide")]
        public Yacht Hide(int id)
        {
            return (_service as IYachtsService).Hide(id);
        }

        [HttpPut("{id}/edit")]
        public Yacht Edit(int id)
        {
            return (_service as IYachtsService).Edit(id);
        }
    }
}
