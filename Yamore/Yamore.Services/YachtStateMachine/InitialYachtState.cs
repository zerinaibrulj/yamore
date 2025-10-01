using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model;
using Yamore.Model.Requests.Yachts;
using Yamore.Services.Database;

namespace Yamore.Services.YachtStateMachine
{
    public class InitialYachtState : BaseYachtState
    {
        public InitialYachtState(_220245Context context, IMapper mapper, IServiceProvider provider) 
            : base(context, mapper, provider)
        {
        }

        public override Model.Yacht Insert(YachtsInsertRequest request)
        {
            var set = Context.Set<Database.Yacht>();
            var entity = Mapper.Map<Database.Yacht>(request);
            //entity.StateMachine = "draft";                         //iz nekog razloga mi podvlaci StateMachine

            set.Add(entity);
            Context.SaveChanges();

            return Mapper.Map<Model.Yacht>(entity);
        }
    }
}
