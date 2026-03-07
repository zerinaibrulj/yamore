using System;

namespace Yamore.Model.Requests.YachtDocument
{
    public class YachtDocumentInsertRequest
    {
        public int YachtId { get; set; }

        public string DocumentType { get; set; } = null!;

        public string? FileName { get; set; }

        public string? FileUrl { get; set; }

        public string? Notes { get; set; }
    }
}
