using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class City
    {
        public int CityId { get; set; }

        public int CountryId { get; set; }

        public string Name { get; set; } = null!;
    }
}
