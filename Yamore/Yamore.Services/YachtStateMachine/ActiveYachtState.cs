using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Services.Database;

namespace Yamore.Services.YachtStateMachine
{
    public class ActiveYachtState : BaseYachtState
    {
        public ActiveYachtState(_220245Context context, IMapper mapper, IServiceProvider serviceProvider) 
            : base(context, mapper, serviceProvider)
        {
        }

        public override Model.Yacht Activate(int id)
        {
            return base.Activate(id);
        }
    }
}
