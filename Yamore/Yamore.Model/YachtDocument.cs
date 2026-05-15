using System;

namespace Yamore.Model
{
    public class YachtDocument
    {
        public int YachtDocumentId { get; set; }
        public int YachtId { get; set; }
        public string DocumentType { get; set; } = null!;
        public string VerificationStatus { get; set; } = YachtDocumentVerificationStatus.Pending;
        public string? ContentType { get; set; }
        public string? FileName { get; set; }
        public DateTime DateUploaded { get; set; }
        public string? RejectionReason { get; set; }
    }
}
