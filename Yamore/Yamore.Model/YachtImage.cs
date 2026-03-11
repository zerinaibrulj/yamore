using System;

namespace Yamore.Model
{
    public class YachtImage
    {
        public int YachtImageId { get; set; }
        public int YachtId { get; set; }
        public string ContentType { get; set; } = null!;
        public string? FileName { get; set; }
        public bool IsThumbnail { get; set; }
        public int SortOrder { get; set; }
        public DateTime DateAdded { get; set; }
    }
}
