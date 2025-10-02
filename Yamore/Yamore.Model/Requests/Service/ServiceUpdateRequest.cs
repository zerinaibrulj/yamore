using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.Requests.Service
{
    public class ServiceUpdateRequest
    {
        public string Name { get; set; } = null!;

        public string? Description { get; set; }

        public decimal? Price { get; set; }
    }
}
