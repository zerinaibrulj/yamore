using System;

namespace Yamore.Services.Database;

public partial class NewsItem
{
    public int NewsId { get; set; }

    public string Title { get; set; } = null!;

    public string Text { get; set; } = null!;

    /// <summary>Public URL to an image (e.g. https://... or same-origin path).</summary>
    public string? ImageUrl { get; set; }

    public DateTime CreatedAt { get; set; }
}
