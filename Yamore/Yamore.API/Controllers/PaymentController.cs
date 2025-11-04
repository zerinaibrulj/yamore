using Microsoft.AspNetCore.Mvc;
using Yamore.Model;
using Yamore.Model.Requests.Payment;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class PaymentController : BaseCRUDController<Model.Payment, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentDeleteRequest>
    {
        public PaymentController(IPaymentService service)
            : base(service)
        {
        }
    }
}
