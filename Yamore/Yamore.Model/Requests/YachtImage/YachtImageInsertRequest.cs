namespace Yamore.Model.Requests.YachtImage
{
    public class YachtImageInsertRequest
    {
        public string ImageDataBase64 { get; set; } = null!;
        public string ContentType { get; set; } = null!;
        public string? FileName { get; set; }
    }
}
