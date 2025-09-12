using System;

namespace Yamore.Model
{
    public class Yachts
    {
        public int YachtId { get; set; }
        public string Name { get; set; }
        public int YearBuilt { get; set; }
        public decimal Length { get; set; }
        public int Capacity { get; set; }
        public decimal PricePerDay { get; set; }
    }
}
