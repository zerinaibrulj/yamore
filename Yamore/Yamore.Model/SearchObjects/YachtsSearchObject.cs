using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class YachtsSearchObject : BaseSearchObject
    {
        public string? FTS { get; set; }
        //public int? Page { get; set; }           // premjestili smo u BaseSearchObject
        //public int? PageSize { get; set; }
    }
}
