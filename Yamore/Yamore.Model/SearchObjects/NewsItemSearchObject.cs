using System;

namespace Yamore.Model.SearchObjects
{
    public class NewsItemSearchObject : BaseSearchObject
    {
        /// <summary>Optional: title contains this substring (case depends on database collation; typically case-insensitive on SQL Server).</summary>
        public string? TitleContains { get; set; }

        /// <summary>Optional: body text contains this substring.</summary>
        public string? TextContains { get; set; }

        public DateTime? CreatedFrom { get; set; }

        public DateTime? CreatedTo { get; set; }
    }
}
