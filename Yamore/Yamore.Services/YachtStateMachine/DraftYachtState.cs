using Azure.Core;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Yachts;
using Yamore.Services.Database;

namespace Yamore.Services.YachtStateMachine
{
    public class DraftYachtState : BaseYachtState
    {
        public DraftYachtState(_220245Context context, IMapper mapper, IServiceProvider serviceProvider) 
            : base(context, mapper, serviceProvider)
        {
        }

        public override Model.Yacht Update(int id, YachtsUpdateRequest request)   // na ovaj nacin smo mi dozvolili Update u stanju "draft"
        {
            var set = Context.Set<Database.Yacht>();
            var entity = set.Find(id);

            Mapper.Map(request, entity);
            Context.SaveChanges();

            return Mapper.Map<Model.Yacht>(entity);
        }

        public override Model.Yacht Activate(int id)
        {
            var set = Context.Set<Database.Yacht>();
            var entity = set.Find(id);

            entity.StateMachine = "active";
            Context.SaveChanges();

            return Mapper.Map<Model.Yacht>(entity);
        }

        public override Model.Yacht Hide(int id)
        {
            var set = Context.Set<Database.Yacht>();
            var entity = set.Find(id);

            entity.StateMachine = "hidden";
            Context.SaveChanges();

            return Mapper.Map<Model.Yacht>(entity);
        }
    }
}
