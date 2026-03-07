using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class ServiceCategory
{
    public int ServiceCategoryId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public virtual ICollection<Service> Services { get; set; } = new List<Service>();
}
