using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Payment;
using Yamore.Model.SearchObjects;
using Yamore.Services.Services;

namespace Yamore.Services.Interfaces
{
    public interface IPaymentService : ICRUDService<Model.Payment, PaymentSearchObject, PaymentInsertRequest, PaymentUpdateRequest, PaymentDeleteRequest>
    {
    }
}
