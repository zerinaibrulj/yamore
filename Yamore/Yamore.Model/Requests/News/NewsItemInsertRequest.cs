using System;

namespace Yamore.Model.Requests.News
{
    public class NewsItemInsertRequest
    {
        public string Title { get; set; } = null!;

        public string Text { get; set; } = null!;

        public string? ImageUrl { get; set; }

        public DateTime? CreatedAt { get; set; }
    }
}
