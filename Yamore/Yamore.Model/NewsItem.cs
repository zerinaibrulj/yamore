using System;

namespace Yamore.Model
{
    public class NewsItem
    {
        public int NewsId { get; set; }

        public string Title { get; set; } = null!;

        public string Text { get; set; } = null!;

        public string? ImageUrl { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
