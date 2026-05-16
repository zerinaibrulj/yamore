using MapsterMapper;
using System;
using System.Collections.Generic;
using Microsoft.Extensions.DependencyInjection;
using Yamore.Model;
using Yamore.Model.Requests.Yachts;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.YachtStateMachine
{
    public class DraftYachtState : BaseYachtState
    {
        public DraftYachtState(_220245Context context, IMapper mapper, IServiceProvider serviceProvider) 
            : base(context, mapper, serviceProvider)
        {
        }

        public override Model.Yacht Update(int id, YachtsUpdateRequest request)  
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
            if (entity == null)
                throw new NotFoundException($"Yacht with id {id} not found.");

            var docService = ServiceProvider.GetRequiredService<IYachtDocumentService>();
            if (!docService.AreMandatoryDocumentsApproved(id))
            {
                throw new UserException(
                    "This yacht cannot be published until Registration, Insurance, and Safety Certificate documents are uploaded and approved by an administrator.");
            }

            entity.StateMachine = YachtStateNames.Active;
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


        public override List<string> AllowedActions(Database.Yacht entity)
        {
            var actions = new List<string> { nameof(Update), nameof(Hide) };
            if (entity != null)
            {
                var docService = ServiceProvider.GetRequiredService<IYachtDocumentService>();
                if (docService.AreMandatoryDocumentsApproved(entity.YachtId))
                    actions.Insert(0, nameof(Activate));
            }

            return actions;
        }
    }
}
