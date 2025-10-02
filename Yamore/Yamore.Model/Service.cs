using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class Service
    {
        public int ServiceId { get; set; }

        public string Name { get; set; } = null!;

        public string? Description { get; set; }

        public decimal? Price { get; set; }
    }
}
