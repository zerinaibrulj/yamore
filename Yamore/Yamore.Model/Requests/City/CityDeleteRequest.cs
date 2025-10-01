using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.City
{
    public class CityDeleteRequest
    {
        public int CountryId { get; set; }

        public string Name { get; set; } = null!;
    }
}
