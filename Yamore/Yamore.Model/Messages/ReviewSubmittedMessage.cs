namespace Yamore.Model.Messages
{
    public class ReviewSubmittedMessage
    {
        public int ReviewId { get; set; }
        public int YachtId { get; set; }
        public int UserId { get; set; }
        public int? Rating { get; set; }
        public string? Comment { get; set; }
    }
}
