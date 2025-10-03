using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class RouteSearchObject : BaseSearchObject
    {
        public int? StartCityId { get; set; }       // stavit cemo ? na sve propertije ako mislimo da nam Get metoda radi i bez da posaljemo parametre po kojima cemo pretrazivati, na ovaj nacin ce nam vratiti sve zapise iz baze

        public int? EndCityId { get; set; }

        public int? EstimatedDurationHours { get; set; }
    }
}
