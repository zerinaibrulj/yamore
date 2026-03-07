using System;

namespace Yamore.Model.Requests.YachtDocument
{
    public class YachtDocumentUpdateRequest
    {
        public int? YachtId { get; set; }

        public string? DocumentType { get; set; }

        public string? FileName { get; set; }

        public string? FileUrl { get; set; }

        public DateTime? VerifiedAt { get; set; }

        public int? VerifiedByUserId { get; set; }

        public string? Notes { get; set; }
    }
}
