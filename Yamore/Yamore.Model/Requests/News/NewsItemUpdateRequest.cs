namespace Yamore.Model.Requests.News
{
    public class NewsItemUpdateRequest
    {
        public string Title { get; set; } = null!;

        public string Text { get; set; } = null!;

        public string? ImageUrl { get; set; }
    }
}
