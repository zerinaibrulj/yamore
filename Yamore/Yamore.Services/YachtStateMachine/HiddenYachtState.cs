using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Services.Database;

namespace Yamore.Services.YachtStateMachine
{
    public class HiddenYachtState : BaseYachtState
    {
        public HiddenYachtState(_220245Context context, IMapper mapper, IServiceProvider serviceProvider) 
            : base(context, mapper, serviceProvider)
        {
        }

        public override Model.Yacht Edit(int id)
        {
            var set = Context.Set<Database.Yacht>();
            var entity = set.Find(id);

            entity.StateMachine = "draft";
            Context.SaveChanges();

            return Mapper.Map<Model.Yacht>(entity);
        }

        public override List<string> AllowedActions(Yacht entity)
        {
            return new List<string> { nameof(Edit) };
        }
    }
}
