using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Yamore.Model
{
    public class PagedResponse<T>
    {
        [JsonPropertyName("count")]
        public int? Count { get; set; }

        [JsonPropertyName("resultList")]
        public IList<T>? ResultList { get; set; }
    }
}
