using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Payment;
using Yamore.Model.SearchObjects;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services
{
    public class PaymentService : BaseCRUDService<Model.Payment, PaymentSearchObject, Database.Payment, PaymentInsertRequest, PaymentUpdateRequest, PaymentDeleteRequest>, IPaymentService
    {
        public PaymentService(_220245Context context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.Payment> AddFilter(PaymentSearchObject search, IQueryable<Database.Payment> query)
        {
            var filteredQurey = base.AddFilter(search, query);

            if (search?.ReservationId != null)
            {
                filteredQurey = filteredQurey.Where(x => x.ReservationId == search.ReservationId);
            }

            if (search?.Status != null)
            {
                filteredQurey = filteredQurey.Where(x => x.Status == search.Status);
            }

            if (!string.IsNullOrWhiteSpace(search?.PaymentMethod))
            {
                filteredQurey = filteredQurey.Where(x => x.PaymentMethod.Contains(search.PaymentMethod));
            }

            return filteredQurey;
        }

    }
}
