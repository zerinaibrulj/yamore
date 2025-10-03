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
    }
}
