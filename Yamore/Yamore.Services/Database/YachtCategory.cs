using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class YachtCategory
{
    public int CategoryId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<Yacht> Yachts { get; set; } = new List<Yacht>();
}
