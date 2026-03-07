using System;

namespace Yamore.Services.Database;

public partial class YachtDocument
{
    public int YachtDocumentId { get; set; }

    public int YachtId { get; set; }

    public string DocumentType { get; set; } = null!;

    public string? FileName { get; set; }

    public string? FileUrl { get; set; }

    public DateTime? VerifiedAt { get; set; }

    public int? VerifiedByUserId { get; set; }

    public string? Notes { get; set; }

    public virtual Yacht Yacht { get; set; } = null!;

    public virtual User? VerifiedByUser { get; set; }
}
