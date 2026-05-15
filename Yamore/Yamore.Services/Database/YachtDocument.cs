using System;

namespace Yamore.Services.Database;

public partial class YachtDocument
{
    public int YachtDocumentId { get; set; }

    public int YachtId { get; set; }

    public string DocumentType { get; set; } = null!;

    public string VerificationStatus { get; set; } = null!;

    public byte[] FileContent { get; set; } = null!;

    public string ContentType { get; set; } = null!;

    public string? FileName { get; set; }

    public DateTime DateUploaded { get; set; }

    public string? RejectionReason { get; set; }

    public virtual Yacht Yacht { get; set; } = null!;
}
