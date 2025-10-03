using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests.Yachts;
using Yamore.Services.Database;

namespace Yamore.Services.YachtStateMachine
{
    public class BaseYachtState
    {
        public _220245Context Context { get; set; }
        public IMapper Mapper { get; set; }
        public IServiceProvider ServiceProvider { get; set; }

        public BaseYachtState(_220245Context context, IMapper mapper, IServiceProvider serviceProvider)
        {
            Context = context;
            Mapper = mapper;
            ServiceProvider = serviceProvider;
        }


        public virtual Model.Yacht Insert(YachtsInsertRequest request)
        {
            throw new Exception("Method not allowed!");
        }


        public virtual Model.Yacht Update(int id, YachtsUpdateRequest request)
        {
            throw new Exception("Method not allowed!");
        }


        public virtual Model.Yacht Activate(int id)
        {
            throw new Exception("Method not allowed!");
        }


        public virtual Model.Yacht Hide(int id)
        {
            throw new Exception("Method not allowed!");
        }



        public BaseYachtState CreateState(string stateName)
        {
            switch (stateName)
            {
                case "initial":
                    return ServiceProvider.GetService<InitialYachtState>();
                case "draft":
                    return ServiceProvider.GetService<DraftYachtState>();
                default:
                    throw new Exception("State not recognized!");
            }
        }

    }
}
