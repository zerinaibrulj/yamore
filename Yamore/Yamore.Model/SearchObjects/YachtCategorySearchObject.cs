using System;
using System.Collections.Generic;
using System.Text;

namespace Yamore.Model.SearchObjects
{
    public class YachtCategorySearchObject
    {
        public string? NameGTE { get; set; }
        public int? Page { get; set; }
        public int? PageSize { get; set; }

    }
}
