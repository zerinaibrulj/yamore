using System;

namespace Yamore.Services.Database;

public partial class YachtImage
{
    public int YachtImageId { get; set; }
    public int YachtId { get; set; }
    public byte[] ImageData { get; set; } = null!;
    public string ContentType { get; set; } = null!;
    public string? FileName { get; set; }
    public bool IsThumbnail { get; set; }
    public int SortOrder { get; set; }
    public DateTime DateAdded { get; set; }

    public virtual Yacht Yacht { get; set; } = null!;
}
