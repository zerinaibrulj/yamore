using System;

namespace Yamore.Model
{
    public class YachtDocument
    {
        public int YachtDocumentId { get; set; }

        public int YachtId { get; set; }

        public string DocumentType { get; set; } = null!;

        public string? FileName { get; set; }

        public string? FileUrl { get; set; }

        public DateTime? VerifiedAt { get; set; }

        public int? VerifiedByUserId { get; set; }

        public string? Notes { get; set; }
    }
}
