 using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model
{
    public class PagedResponse<T>       // Sluzi da vratimo COUNT objekata iz baze kao i listu tih objekata
    {
        public int? Count { get; set; }
        public IList<T>? ResultList { get; set; }
    }
}
