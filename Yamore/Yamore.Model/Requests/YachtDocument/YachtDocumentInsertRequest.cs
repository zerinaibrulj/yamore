namespace Yamore.Model.Requests.YachtDocument
{
    public class YachtDocumentInsertRequest
    {
        public string DocumentType { get; set; } = null!;
        public string FileDataBase64 { get; set; } = null!;
        public string ContentType { get; set; } = null!;
        public string? FileName { get; set; }
    }
}
