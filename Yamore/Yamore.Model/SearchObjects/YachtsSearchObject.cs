using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class YachtsSearchObject : BaseSearchObject
    {
        public string? NameGTE { get; set; }
        public int? YearBuilt { get; set; }
        public int? Capacity { get; set; }
        /// <summary>Minimum capacity (number of people).</summary>
        public int? CapacityMin { get; set; }
        /// <summary>Maximum capacity (number of people).</summary>
        public int? CapacityMax { get; set; }
        public decimal? PricePerDay { get; set; }
        public decimal? PricePerDayMin { get; set; }
        public decimal? PricePerDayMax { get; set; }
        /// <summary>Yacht location (city).</summary>
        public int? LocationId { get; set; }
        /// <summary>Filter by city (any city in country).</summary>
        public int? CityId { get; set; }
        /// <summary>Filter by country (yacht location's country).</summary>
        public int? CountryId { get; set; }
        /// <summary>Start of desired availability period (for search).</summary>
        public DateTime? AvailableFrom { get; set; }
        /// <summary>End of desired availability period (for search).</summary>
        public DateTime? AvailableTo { get; set; }
        public string? OrderBy { get; set; }
    }
}
