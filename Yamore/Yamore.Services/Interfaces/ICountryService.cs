using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yamore.Model.Requests;
using Yamore.Model.SearchObjects;

namespace Yamore.Services.Interfaces
{
    public interface ICountryService : ICRUDService<Model.Country, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest>
    {
    }
}
