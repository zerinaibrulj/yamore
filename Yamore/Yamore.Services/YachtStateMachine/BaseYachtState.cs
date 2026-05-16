using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;
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


        public virtual Model.Yacht Insert(YachtsInsertRequest request, int ownerUserId)
        {
            throw new UserException("Method not allowed!");
        }


        public virtual Model.Yacht Update(int id, YachtsUpdateRequest request)
        {
            throw new UserException("Method not allowed!");
        }


        public virtual Model.Yacht Activate(int id)
        {
            throw new UserException("Method not allowed!");
        }


        public virtual Model.Yacht Hide(int id)
        {
            throw new UserException("Method not allowed!");
        }

        public virtual Model.Yacht Edit(int id)
        {
            throw new UserException("Method not allowed!");
        }


        public virtual List<string> AllowedActions(Database.Yacht entity)
        {
            throw new UserException("Method not allowed!");
        }



        public BaseYachtState CreateState(string? stateName)
        {
            var normalized = string.IsNullOrWhiteSpace(stateName)
                ? YachtStateNames.Draft
                : stateName.Trim().ToLowerInvariant();

            return normalized switch
            {
                YachtStateNames.Initial => ServiceProvider.GetRequiredService<InitialYachtState>(),
                YachtStateNames.Draft => ServiceProvider.GetRequiredService<DraftYachtState>(),
                YachtStateNames.Active => ServiceProvider.GetRequiredService<ActiveYachtState>(),
                YachtStateNames.Hidden => ServiceProvider.GetRequiredService<HiddenYachtState>(),
                _ => throw new InvalidOperationException($"Yacht state is not recognized: {stateName}."),
            };
        }
    }
}
